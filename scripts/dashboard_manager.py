import time
import subprocess
import sys
import os
import signal
from threading import Thread
import multiprocessing as mp

# Handle the 3 process outputs concurrently
# Multiprocessing requires top-level functions
def enqueue_output(print_queue, prefix, command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    while True:
        try:
            nextline = process.stdout.readline()
            if len(nextline) > 0:
                # Skip printing of ETA lines
                if prefix == '$$' and b'[==============================]' in nextline:
                    continue
                else:
                    print_queue.put(prefix + ' ' + str(nextline.decode('utf-8')))
        except KeyboardInterrupt:
            return
        except:
            print_queue.put(prefix + ' ' + "Fallback error")

# For the dashboard, start these scripts:
# 1. test_server.py, wait until "[LISTENING] Server is listening on localhost"
# 2. identify_keyword.py, wait until "addr1 combined successfully!"
# 3. mic_test_filter_comms.py
def main():
    # Start multiprocessing processes
    mp.set_start_method('spawn')
    mp_queue = mp.Queue()

    # Process 1
    print("* Launching test_server.py")
    command1 = "python3 -u ../intel_Cup_keyword_identifier/test_server.py"
    t1 = mp.Process(target=enqueue_output, args=(mp_queue, '@@', command1,))
    t1.daemon = True # thread dies with the program
    t1.start()
    while True:
        nextline = mp_queue.get()
        sys.stdout.write(nextline)
        if "@@ [LISTENING] " in nextline:
            break

    # Process 2
    print("* Launching identify_keyword.py")
    command2 = "python3 -u ../intel_Cup_keyword_identifier/identify_keyword.py"
    t2 = mp.Process(target=enqueue_output, args=(mp_queue, '>>', command2,))
    t2.daemon = True # thread dies with the program
    t2.start()
    while True:
        nextline = mp_queue.get()
        sys.stdout.write(nextline)
        if ">> addr1 combined successfully!" in nextline:
            break

    # Process 3
    print("* Launching mic_test_filter_comms.py")
    command3 = "python3 -u ../intel_Cup_keyword_identifier/mic_test_filter_comms.py"
    t3 = mp.Process(target=enqueue_output, args=(mp_queue, '$$', command3,))
    t3.daemon = True # thread dies with the program
    t3.start()

    # Make the processes close upon quitting the manager
    def signal_handler(signal, frame):
        t1.terminate()
        t2.terminate()
        t3.terminate()
        print("Dashboard Exiting", flush=True)
        sys.exit(0)
    signal.signal(signal.SIGINT, signal_handler)

    # Idle until the end of program
    while True:
        # print() was causing race condition,
        # write directly to stdout instead
        try:
            nextline = mp_queue.get()
            sys.stdout.write(str(nextline))
        except Exception as e:
            raise Exception("The error is:" + str(nextline))
            print("Main thread error", e)
            break

    print("Dashboard Stopped", flush=True)

if __name__ == "__main__":
    main()
