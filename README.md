### This is an emulated version of DRb server (Leader) + Workers
The application is designed to emulate various methods of synchronizing several arrays located in different threads and interconnected via DRb.
We encountered a problem using the Mutex that led to a deadlock


### How to run
`ruby app.rb`

### How to configure
You can configure params in the file app.rb
```
NUMBER_OF_WORKERS # Number of workers to emulate
FILES_TO_RUN_PERCENTAGE = 100 # Emulate running only part of the tests
FILE_TO_RETURN_BY_TIMEOUT_PERCENTAGE = 0 # (1..5) Emulate timeout by randomly repushing tests back to the queue
WORKER_PROCESS_TEST_TIME = 0.1 # Emulate test running time
MULTIPLIER = 1 # Emulate tests count multiplier (to emulate big amount of tests)
```
