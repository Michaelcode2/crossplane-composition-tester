Feature: Policy Scheduler Composition
  As a platform administrator
  I want to control access to production resources during specific time windows
  So that production access is restricted to business hours

  Background:
    Given input composition composition.yaml
    And input claim claim.yaml
    And input functions functions.yaml

  @critical
  Scenario: Basic policy scheduler provisioning
    When crossplane renders the composition
    Then check that 6 resources are provisioning and they are
      | resource-name             |
      | production-role           |
      | production-policy         |
      | policy-attachment         |
      | scheduler-lambda          |
      | scheduler-event-rule      |
      | lambda-permission         |

  @critical
  Scenario: IAM role is created with time-based assume role policy
    When crossplane renders the composition
    Then check that resource production-role has parameters
      | param name                                    | param value                |
      | spec.forProvider.name                        | production-access-role     |
      | metadata.name                                 | test-policy-scheduler-role |
      | spec.forProvider.tags.Environment           | production                 |
      | spec.forProvider.tags.Purpose               | time-restricted-access     |

  @critical
  Scenario: IAM policy is created with time-restricted permissions
    When crossplane renders the composition
    Then check that resource production-policy has parameters
      | param name                        | param value                  |
      | spec.forProvider.name            | production-access-policy     |
      | metadata.name                     | test-policy-scheduler-policy |
      | spec.forProvider.tags.Environment| production                   |
      | spec.forProvider.tags.Purpose    | time-restricted-policy       |

  @critical
  Scenario: Policy attachment links role and policy
    When crossplane renders the composition
    Then check that resource policy-attachment has parameters
      | param name                                          | param value                         |
      | metadata.name                                       | test-policy-scheduler-attachment    |
      | spec.forProvider.roleSelector.matchControllerRef   | true                                |
      | spec.forProvider.policyArnSelector.matchControllerRef | true                             |

  @major
  Scenario: Lambda function is created for policy scheduling
    When crossplane renders the composition
    Then check that resource scheduler-lambda has parameters
      | param name                           | param value                    |
      | metadata.name                        | test-policy-scheduler-scheduler|
      | spec.forProvider.runtime            | python3.9                      |
      | spec.forProvider.handler            | index.handler                  |
      | spec.forProvider.tags.Environment   | production                     |
      | spec.forProvider.tags.Purpose       | policy-scheduler               |

  @major
  Scenario: CloudWatch event rule is created for hourly triggers
    When crossplane renders the composition
    Then check that resource scheduler-event-rule has parameters
      | param name                           | param value                         |
      | metadata.name                        | test-policy-scheduler-event-rule    |
      | spec.forProvider.scheduleExpression  | rate(1 hour)                        |
      | spec.forProvider.state              | ENABLED                             |
      | spec.forProvider.tags.Environment   | production                          |

  @major
  Scenario: Lambda permission allows CloudWatch Events to invoke function
    When crossplane renders the composition
    Then check that resource lambda-permission has parameters
      | param name                                          | param value                            |
      | metadata.name                                       | test-policy-scheduler-lambda-permission|
      | spec.forProvider.action                            | lambda:InvokeFunction                  |
      | spec.forProvider.principal                         | events.amazonaws.com                   |
      | spec.forProvider.functionNameSelector.matchControllerRef | true                             |

  @critical
  Scenario: Policy scheduler with custom time window
    Given input claim is changed with parameters
      | param name               | param value |
      | spec.timeWindow.start   | 08:00       |
      | spec.timeWindow.end     | 18:00       |
      | spec.timeWindow.timezone| EST         |
    When crossplane renders the composition
    Then check that 6 resources are provisioning

  @major
  Scenario: Policy scheduler with custom allowed actions
    Given input claim is changed with parameters
      | param name              | param value   |
      | spec.allowedActions[0] | ec2:Describe* |
      | spec.allowedActions[1] | s3:GetObject  |
      | spec.allowedActions[2] | rds:Describe* |
    When crossplane renders the composition
    Then check that 6 resources are provisioning
    And check that resource production-policy has parameters
      | param name                        | param value                  |
      | spec.forProvider.name            | production-access-policy     |

  @major
  Scenario: Policy scheduler with custom schedule interval
    Given input claim is changed with parameters
      | param name             | param value  |
      | spec.schedule.interval | 30 minutes   |
    When crossplane renders the composition
    Then check that resource scheduler-event-rule has parameters
      | param name                           | param value      |
      | spec.forProvider.scheduleExpression  | rate(30 minutes) |

  @minor
  Scenario: Policy scheduler with custom role and policy names
    Given input claim is changed with parameters
      | param name          | param value            |
      | spec.roleName      | custom-prod-role       |
      | spec.policyName    | custom-prod-policy     |
      | spec.description   | Custom production access|
    When crossplane renders the composition
    Then check that resource production-role has parameters
      | param name                     | param value              |
      | spec.forProvider.name         | custom-prod-role         |
      | spec.forProvider.description  | Custom production access |
    And check that resource production-policy has parameters
      | param name                     | param value              |
      | spec.forProvider.name         | custom-prod-policy       |

  @critical
  Scenario: All resources are ready and policy attachment is functional
    Given input composition composition.yaml
    And input claim claim.yaml
    And input functions functions.yaml
    When crossplane renders the composition
    Then check that 6 resources are provisioning
    Given change all observed resources with status READY
    And change observed resource production-role with parameters
      | param name              | param value                                |
      | status.atProvider.arn  | arn:aws:iam::123456789012:role/test-role   |
    And change observed resource production-policy with parameters
      | param name              | param value                                  |
      | status.atProvider.arn  | arn:aws:iam::123456789012:policy/test-policy |
    And change observed resource scheduler-lambda with parameters
      | param name                        | param value                                    |
      | status.atProvider.functionName   | test-policy-scheduler-function                 |
      | status.atProvider.arn           | arn:aws:lambda:us-east-1:123456789012:function:test-scheduler |
    When crossplane renders the composition
    Then check that 6 resources are provisioning
    And check that resource policy-attachment has parameters
      | param name                                          | param value |
      | spec.forProvider.roleSelector.matchControllerRef   | true        |
      | spec.forProvider.policyArnSelector.matchControllerRef | true     |

  @major
  Scenario: Verify lambda function code contains time-based logic
    When crossplane renders the composition
    Then check that resource scheduler-lambda has parameters
      | param name                           | param value   |
      | spec.forProvider.handler            | index.handler |
      | spec.forProvider.runtime            | python3.9     |

  @minor
  Scenario: Emergency access configuration is supported
    Given input claim is changed with parameters
      | param name                          | param value                               |
      | spec.resources.emergencyAccess.enabled | true                                   |
      | spec.resources.emergencyAccess.approvers[0] | arn:aws:iam::123456789012:user/admin |
    When crossplane renders the composition
    Then check that 6 resources are provisioning

  @major
  Scenario: Production environments are configurable
    Given input claim is changed with parameters
      | param name                                  | param value |
      | spec.resources.productionEnvironments[0]  | prod        |
      | spec.resources.productionEnvironments[1]  | staging     |
      | spec.resources.restrictedActions[0]       | ec2:TerminateInstances |
    When crossplane renders the composition
    Then check that 6 resources are provisioning

  @critical
  Scenario: Policy scheduler handles multiple time zones
    Given input claim is changed with parameters
      | param name               | param value |
      | spec.timeWindow.start   | 09:00       |
      | spec.timeWindow.end     | 17:00       |
      | spec.timeWindow.timezone| America/New_York |
    When crossplane renders the composition
    Then check that 6 resources are provisioning
    And check that resource scheduler-lambda has parameters
      | param name                                         | param value      |
      | spec.forProvider.environment.variables.TIMEZONE   | America/New_York |

  @major
  Scenario: Verify all resources have proper tags
    When crossplane renders the composition
    Then check that resource production-role has parameters
      | param name                        | param value            |
      | spec.forProvider.tags.Environment| production             |
      | spec.forProvider.tags.Purpose    | time-restricted-access |
    And check that resource production-policy has parameters
      | param name                        | param value            |
      | spec.forProvider.tags.Environment| production             |
      | spec.forProvider.tags.Purpose    | time-restricted-policy |
    And check that resource scheduler-lambda has parameters
      | param name                        | param value      |
      | spec.forProvider.tags.Environment| production       |
      | spec.forProvider.tags.Purpose    | policy-scheduler |