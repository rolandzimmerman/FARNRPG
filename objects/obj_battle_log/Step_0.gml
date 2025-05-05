// Auto‐advance the log one line at a time
if (currentIndex < array_length(logEntries) - 1) {
    timer++;
    if (timer >= advanceDelay) {
        timer = 0;
        currentIndex++;
    }
}
