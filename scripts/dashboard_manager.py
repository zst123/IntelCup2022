import time
import subprocess
import sys
import os
import signal
from threading import Thread

# For the dashboard, start these scripts:
# 1. test_server.py, wait until "[LISTENING] Server is listening on localhost"
# 2. identify_keyword.py, wait until "addr1 combined successfully!"
# 3. mic_test_filter_comms.py
def main():
    # Process 1
    print("* Launching test_server.py")
    command1 = "python3 -u ../intel_Cup_keyword_identifier/test_server.py"
    process1 = subprocess.Popen(command1, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    while True:
        nextline = process1.stdout.readline()
        if len(nextline) == 0:
            continue
        print("@@", nextline.decode(), end="", flush=True)
        if b"[LISTENING] " in nextline:
            break

    # Process 2
    print("* Launching identify_keyword.py")
    command2 = "python3 -u ../intel_Cup_keyword_identifier/identify_keyword.py"
    process2 = subprocess.Popen(command2, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    while True:
        nextline2 = process2.stdout.readline()
        if len(nextline2) == 0:
            continue
        print(">>", nextline2.decode(), end="", flush=True)
        if b"addr1 combined successfully!" in nextline2:
            break

    # Process 3
    print("* Launching mic_test_filter_comms.py")
    command3 = "python3 -u ../intel_Cup_keyword_identifier/mic_test_filter_comms.py"
    process3 = subprocess.Popen(command3, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    # Make the processes close upon quitting the manager
    def signal_handler(signal, frame):
        process1.kill()
        process2.kill()
        process3.kill()
        print("Dashboard Exiting", flush=True)
        sys.exit(0)
    signal.signal(signal.SIGINT, signal_handler)

    # Handle the 3 process outputs concurrently
    def enqueue_output(prefix, out):
        while True:
            nextline = out.readline()
            if len(nextline) > 0:
                print(prefix, nextline.decode(), end="", flush=True)
                # sys.stdout.flush()

    t1 = Thread(target=enqueue_output, args=('@@', process1.stdout,))
    t1.daemon = True # thread dies with the program
    t1.start()
    t2 = Thread(target=enqueue_output, args=('>>', process2.stdout,))
    t2.daemon = True # thread dies with the program
    t2.start()
    t3 = Thread(target=enqueue_output, args=('$$', process3.stdout,))
    t3.daemon = True # thread dies with the program
    t3.start()

    # Idle until the end of program
    while True:
        time.sleep(1)
    print("Dashboard Stopped", flush=True)

if __name__ == "__main__":
    main()
