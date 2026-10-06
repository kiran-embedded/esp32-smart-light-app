class DailyQuotes {
  static const List<String> quotes = [
    "Small controls, a smarter tomorrow.",
    "Intelligence is the ability to adapt to change.",
    "The best way to predict the future is to invent it.",
    "Innovation distinguishes between a leader and a follower.",
    "Simplicity is the ultimate sophistication.",
    "Automation is cost cutting by tightening the corners.",
    "Design is not just what it looks like and feels like. Design is how it works.",
    "Technology is best when it brings people together.",
    "Make it simple, but significant.",
    "The real problem is not whether machines think but whether men do.",
    "Any sufficiently advanced technology is indistinguishable from magic.",
    "Good design is obvious. Great design is transparent.",
    "It has become appallingly obvious that our technology has exceeded our humanity.",
    "Just because something doesn’t do what you planned it to do doesn’t mean it’s useless.",
    "The art of simplicity is a puzzle of complexity.",
    "A smarter home for a better life.",
    "Efficiency is doing things right; effectiveness is doing the right things.",
    "Focus on being productive instead of busy.",
    "The advance of technology is based on making it fit in so that you don't really even notice it.",
    "Let the environment adapt to you.",
    "Your home, your rules, automated.",
    "Seamless control at your fingertips.",
    "Every day is a step towards a brighter, smarter future.",
    "Dream big, automate small.",
    "Less friction, more freedom.",
    "Connect your world, simplify your life.",
    "Smart living is an art.",
    "The quiet revolution of smart homes.",
    "Bring harmony to your environment.",
    "Tomorrow's technology, today's convenience."
  ];

  static String getQuoteForToday() {
    final now = DateTime.now();
    final dayOfYear = int.parse("${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}");
    return quotes[dayOfYear % quotes.length];
  }
}
