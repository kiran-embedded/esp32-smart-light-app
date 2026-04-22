import json
import numpy as np
import tensorflow as tf
import os
import re

print("Initializing TensorFlow...")

# --- DATASET ---
intents = [
    # GREETINGS
    {"tag": "greeting", "patterns": ["hello", "hi", "hey", "greetings", "good morning", "good evening", "sup", "howdy", "wake up"]},
    {"tag": "farewell", "patterns": ["bye", "goodbye", "see you", "night", "good night", "sleep"]},
    
    # HARDWARE & ARCHITECTURE AWARENESS
    {"tag": "hardware_explain", "patterns": ["how do you work", "what is your brain", "what processor do you use", "hardware architecture", "tell me about your hardware"]},
    {"tag": "ai_origin", "patterns": ["are you ai", "who are you", "what is nebula", "tensorflow", "how were you trained", "are you smart"]},
    
    # FIRMWARE GENERATION & FIREBASE
    {"tag": "generate_esp32_firmware", "patterns": ["create esp32 firmware", "give me esp32 code", "write esp32 firmware", "make esp32 code", "generate esp32 script", "esp32 arduino code"]},
    {"tag": "generate_esp8266_firmware", "patterns": ["create esp8266 firmware", "give me esp8266 code", "write esp8266 firmware", "make esp8266 code", "generate esp8266 script", "esp8266 arduino code", "satellite firmware"]},
    {"tag": "firebase_details", "patterns": ["tell me about firebase", "what is the firebase address", "firebase details", "how does firebase work", "firebase connection", "realtime database"]},
    {"tag": "general_query", "patterns": ["what can you do", "explain this app", "technical details of the app", "how to use this"]},
    
    # DEEP ARCHITECTURE & DEVELOPER ("Kirancybergrid")
    {"tag": "developer_info", "patterns": ["who created you", "who is your developer", "kirancybergrid", "github developer", "who made this app", "creator"]},
    {"tag": "app_structure", "patterns": ["how is this app built", "app structure", "what framework", "riverpod", "state management", "flutter code"]},
    {"tag": "theme_engine", "patterns": ["how to change colors", "theme engine", "what themes are available", "ui design", "indexedstack"]},
    {"tag": "security_engine", "patterns": ["security module", "how does security work", "features of security", "pir sensor", "alarm systems", "protect the house"]},
    {"tag": "telemetry_optimization", "patterns": ["how does telemetry work", "firebase optimizations", "server cost", "data rate", "optimization"]},
    
    # EMOTION & EQ
    {"tag": "feeling_sad", "patterns": ["im sad", "lonely", "depressed", "had a bad day", "feeling down"]},
    {"tag": "feeling_stressed", "patterns": ["im stressed", "exhausted", "tired", "need a break", "worked too hard"]},
    {"tag": "compliment", "patterns": ["you are awesome", "good job", "love you", "cool ai", "thanks", "thank you"]},
    
    # DEVICE CONTROL - MULTIMODE MASSIVE PERMUTATIONS
    {"tag": "lights_on", "patterns": ["turn on the lights", "all lights on", "activate lights", "switch everything on", "light up the room", "please switch on lights", "lights on now", "can you turn lights on", "illuminate the area", "make it bright", "turn all bulbs on", "switching on the lights"]},
    {"tag": "lights_off", "patterns": ["turn off the lights", "all lights off", "darkness", "turn everything off", "shutdown", "switch off the lights", "please turn off lights", "kill the lights", "make it dark", "turning off all lights"]},
    
    {"tag": "relay_1_on", "patterns": ["turn on relay 1", "relay 1 active", "start relay 1", "switch on relay 1", "please turn on relay 1", "activating relay 1", "relay 1 on"]},
    {"tag": "relay_1_off", "patterns": ["turn off relay 1", "relay 1 down", "stop relay 1", "switch off relay 1", "please turn off relay 1", "deactivating relay 1", "relay 1 off"]},
    {"tag": "relay_2_on", "patterns": ["turn on relay 2", "relay 2 active", "start relay 2", "switch on relay 2", "please turn on relay 2", "activating relay 2", "relay 2 on"]},
    {"tag": "relay_2_off", "patterns": ["turn off relay 2", "relay 2 down", "stop relay 2", "switch off relay 2", "please turn off relay 2", "deactivating relay 2", "relay 2 off"]},
    
    # SECURITY
    {"tag": "security_arm", "patterns": ["arm security", "lock down", "turn on alarms", "guard the house", "activate security", "lock everything down", "start guarding", "securing the area"]},
    {"tag": "security_disarm", "patterns": ["disarm security", "safe to enter", "turn off alarms", "unlock", "deactivate security", "stop guarding", "shut down security"]},
    
    # THEMES
    {"tag": "theme_neon", "patterns": ["cyber neon theme", "neon lights", "make it neon", "bright theme", "hacker mode"]},
    {"tag": "theme_dark", "patterns": ["dark space theme", "dark mode", "make it dark", "space theme"]},
]

words = []
classes = []
documents = []

def simple_stemmer(word):
    """
    Strips common suffixes to drastically reduce Vocabulary dimensional bloating 
    while preserving matching power. Mimics edge device computational bounds.
    """
    if len(word) <= 3:
        return word
    if word.endswith('ing'):
        return word[:-3]
    if word.endswith('ed'):
        return word[:-2]
    if word.endswith('es'):
        return word[:-2]
    if word.endswith('s') and not word.endswith('ss'):
        return word[:-1]
    return word

def clean_word(word):
    cleaned = re.sub(r'[^a-zA-Z]', '', word).lower()
    return simple_stemmer(cleaned)

# Process data
for intent in intents:
    for pattern in intent["patterns"]:
        w = [clean_word(word) for word in pattern.split() if clean_word(word) != '']
        words.extend(w)
        documents.append((w, intent["tag"]))
        if intent["tag"] not in classes:
            classes.append(intent["tag"])

words = sorted(list(set(words)))
classes = sorted(list(set(classes)))

print(f"{len(documents)} patterns")
print(f"{len(classes)} classes")
print(f"{len(words)} unique words (STEMMED)")

# Create Training Data (Bag of Words)
training = []
output_empty = [0] * len(classes)

for doc in documents:
    bag = []
    pattern_words = doc[0]
    for w in words:
        bag.append(1 if w in pattern_words else 0)
        
    output_row = list(output_empty)
    output_row[classes.index(doc[1])] = 1
    training.append([bag, output_row])

import random
random.shuffle(training)

train_x = np.array([row[0] for row in training])
train_y = np.array([row[1] for row in training])

print("Building TensorFlow Keras Model...")
# Simple 2-layer Neural Network suitable for flutter math rendering
model = tf.keras.Sequential([
    tf.keras.layers.InputLayer(input_shape=(len(train_x[0]),)),
    tf.keras.layers.Dense(64, activation='relu', kernel_regularizer=tf.keras.regularizers.L2(0.001)),
    tf.keras.layers.Dropout(0.1),
    tf.keras.layers.Dense(len(train_y[0]), activation='softmax')
])

model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

print("Training Model...")
model.fit(train_x, train_y, epochs=200, batch_size=4, verbose=1)

# Extract Math Formatted Weights for Dart
print("Exporting Matrices...")
layer1_w, layer1_b = model.layers[0].get_weights()
layer2_w, layer2_b = model.layers[2].get_weights()

export_data = {
    "vocabulary": words,
    "classes": classes,
    "layer1_weights": layer1_w.tolist(),
    "layer1_bias": layer1_b.tolist(),
    "layer2_weights": layer2_w.tolist(),
    "layer2_bias": layer2_b.tolist(),
}

output_path = "assets/ai_model.json"
os.makedirs(os.path.dirname(output_path), exist_ok=True)
with open(output_path, "w") as f:
    json.dump(export_data, f)

print(f"\nTraining Complete! Matrices dumped to {output_path}")
print("Flutter can now perform deep neural inference locally via pure Dart math!")
