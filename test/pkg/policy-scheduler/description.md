### Composition.yml requirements:

        template: |-
          {{/* TODO: implement the composition with one or more steps. The function can be any function from https://github.com/crossplane-contrib?q=function or custom one. Explain your choice. */}}
          {{/* TODO: the composition must: */}}
          {{/*  1. handle all schedules from the schedules list */}}
          {{/*  2. for each schedule: provision the role and assign the policy ONLY during the time interval specified by the scheduleFrom and scheduleUntil */}}
          {{/* TODO: write composition tests to demonstrate how the composition functions; write as many relevant tests as you consider. Justify the choices made! */}}
          {{/* HINT 1: Make use of tags to run a sub set of tests. For example: ./tests_runner.sh test -t PolicyScheduler -t normal */}}
          {{/* HINT 2: Make use of debug flag to get the observed and desired states of each crossplane iteration. Check ./dump folder. For example: ./tests_runner.sh test -d */}}


## Technical Architecture:

#### The solution creates a complete AWS infrastructure stack that:

- IAM Role: With time-based assume role policies
- IAM Policy: Containing production permissions with time restrictions
- Lambda Function: Contains intelligent scheduling logic with timezone support
- CloudWatch Events: Triggers policy checks on configurable intervals
- Proper Integrations: All resources are linked with Crossplane controller references

#### Key Features Implemented:

- Time-Based Access Control: Automatic policy attachment/detachment during configured hours
- Lambda Automation: Python function that manages policy state based on current time
- Configurable Schedules: Support for different time zones and check intervals
- Security Best Practices: Principle of least privilege, proper tagging, audit logging

#### Testing Coverage:

- Critical scenarios (8 tests): Core functionality and security
- Major scenarios (10 tests): Advanced features and customization
- Minor scenarios (4 tests): Edge cases and configuration options
- Edge case scenarios (12 tests): Boundary conditions and error handling


## Development Workflow:

#### Phase 1: Local Development (No K8s)

```
# 1. Develop compositions locally
# 2. Test with crossplane render
# 3. Run BDD tests with behave
# 4. Iterate
```

#### Phase 2: Integration Testing (GitHub pipeline)

```
# 1. Use Kind for full integration tests
# 2. Test actual AWS provider integration
# 3. Validate real resource creation
```

### File Structure for Local Testing:

Structure created in the crossplane-composition-tester repo:

```
test/
├── functions.yaml                              # Functions config
├── pkg/
│   └── policy-scheduler/
│       └── composition.yaml                    # composition
        └── definition.yaml                     # Definition file
└── composition-tests/
    └── policy-scheduler/
        ├── main.feature                        # BDD general tests
        ├── edge-case-tests.feature             # BDD cases tests
        └── resources/
            └── claim.yaml                      # Test claim
```

## Testing Options:

Run tests locally or in GitHub actions

```
# run all tests:
behave test/composition-tests/policy-scheduler/
# Run defined testfile:
behave test/composition-tests/policy-scheduler/main.feature
# Run defined tests in the test file:
behave test/composition-tests/policy-scheduler/main.feature \
  --tags=critical \
  --name="Basic policy scheduler provisioning"
```

Run bash test script:

```
./tests_runner.sh --debug --tags critical test
```
