const functions = require('firebase-functions');
const { smarthome } = require('actions-on-google');
const admin = require('firebase-admin');

admin.initializeApp();

const app = smarthome({
    debug: true,
});

// 1. SYNC Intent: Returns the user's devices to Google Home App
app.onSync(async (body, requestId) => {
    const userId = body.agentUserId || 'test_user'; // In production, get from OAuth token
    const devicesSnapshot = await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('devices')
        .get();

    const devices = devicesSnapshot.docs.map(doc => {
        const data = doc.data();
        return {
            id: doc.id,
            type: 'action.devices.types.LIGHT',
            traits: [
                'action.devices.traits.OnOff',
            ],
            name: {
                defaultNames: ['Nebula Smart Light'],
                name: data.nickname || `Relay ${doc.id.replace('relay', '')}`,
                nicknames: [data.nickname || 'Smart Switch'],
            },
            willReportState: true,
            deviceInfo: {
                manufacturer: 'Nebula Core',
                model: 'ESP32-Grid-V1',
                hwVersion: '1.2.0',
                swVersion: '1.2.0',
            },
        };
    });

    return {
        requestId: body.requestId,
        payload: {
            agentUserId: userId,
            devices: devices,
        },
    };
});

// 2. QUERY Intent: Returns current device states
app.onQuery(async (body) => {
    const { devices } = body.payload;
    const userId = body.agentUserId || 'test_user';
    const deviceStates = {};

    const fetches = devices.map(async (device) => {
        const doc = await admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(device.id)
            .get();

        if (doc.exists) {
            deviceStates[device.id] = {
                on: doc.data().isActive,
                online: true,
            };
        } else {
            deviceStates[device.id] = {
                online: false,
            };
        }
    });

    await Promise.all(fetches);

    return {
        requestId: body.requestId,
        payload: {
            devices: deviceStates,
        },
    };
});

// 3. EXECUTE Intent: Performs actions on devices
app.onExecute(async (body) => {
    const userId = body.agentUserId || 'test_user';
    const commands = body.payload.commands;
    const results = [];

    for (const command of commands) {
        for (const device of command.devices) {
            for (const execution of command.execution) {
                if (execution.command === 'action.devices.commands.OnOff') {
                    const newState = execution.params.on;
                    await admin.firestore()
                        .collection('users')
                        .doc(userId)
                        .collection('devices')
                        .doc(device.id)
                        .update({ isActive: newState });

                    results.push({
                        ids: [device.id],
                        status: 'SUCCESS',
                        states: {
                            on: newState,
                            online: true,
                        },
                    });
                }
            }
        }
    }

    return {
        requestId: body.requestId,
        payload: {
            commands: results,
        },
    };
});

exports.smarthomeFulfillment = functions.https.onRequest(app);

// 4. Firestore Trigger: Auto-Reports state to Google when DB changes
exports.reportStateTrigger = functions.firestore
    .document('users/{userId}/devices/{deviceId}')
    .onUpdate(async (change, context) => {
        const userId = context.params.userId;
        const deviceId = context.params.deviceId;
        const newData = change.after.data();

        console.log(`Reporting state for ${deviceId} (User: ${userId}) -> ${newData.isActive}`);

        try {
            await app.reportState({
                requestId: Math.random().toString(16).slice(2),
                agentUserId: userId,
                payload: {
                    devices: {
                        states: {
                            [deviceId]: {
                                on: newData.isActive,
                            },
                        },
                    },
                },
            });
            console.log('Report state successful');
        } catch (e) {
            console.error('Error reporting state to Google:', e);
        }
    });
