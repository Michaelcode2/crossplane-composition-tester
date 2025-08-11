Feature: Policy Scheduler Edge Cases and Error Handling
  As a platform administrator
  I want the policy scheduler to handle edge cases gracefully
  So that the system remains stable under various conditions

  Background:
    Given input composition composition.yaml
    And input claim claim.yaml
    And input functions functions.yaml

  @critical
  Scenario: Policy scheduler handles midnight time window crossing
    Given input claim is changed with parameters
      | param name               | param value |
      | spec.timeWindow.start   | 22:00       |
      | spec.timeWindow.end     | 06:00       |
    When crossplane renders the composition
    Then check that 6 resources are provisioning
    And check that resource scheduler-lambda has parameters
      | param name                                         | param value |
      | spec.forProvider.environment.variables.START_TIME | 22:00       |
      | spec.forProvider.environment.variables.END_TIME   | 06:00       |

  @major
  Scenario: Policy scheduler with minimal access window
    Given input claim is changed with parameters
      | param name               | param value |
      | spec.timeWindow.start   | 12:00       |
      | spec.timeWindow.end     | 12:15       |
      | spec.schedule.interval  | 15 minutes  |
    When crossplane renders the composition
    Then check that 6 resources are provisioning
    And check that resource scheduler-event-rule has parameters
      | param name                           | param value       |
      | spec.forProvider.scheduleExpression  | rate(15 minutes)  |

  @major
  Scenario: Policy scheduler with maximum allowed actions
    Given input claim is changed with parameters
      | param name              | param value     |
      | spec.allowedActions[0] | ec2:*           |
      | spec.allowedActions[1] | s3:*            |
      | spec.allowedActions[2] | rds:*           |
      | spec.allowedActions[3] | lambda:*        |
      | spec.allowedActions[4] | cloudwatch:*    |
      | spec.allowedActions[5] | logs:*          |
    When crossplane renders the composition
    Then check that 6 resources are provisioning

  @critical
  Scenario: Policy scheduler with emergency access enabled
    Given input claim is changed with parameters
      | param name                              | param value                                    |
      | spec.resources.emergencyAccess.enabled | true                                           |
      | spec.resources.emergencyAccess.approvers[0] | arn:aws:iam::123456789012:user/emergency-admin |
      | spec.resources.emergencyAccess.approvers[1] | arn:aws:iam::123456789012:role/incident-response |
    When crossplane renders the composition
    Then check that 6 resources are provisioning

  @major
  Scenario: Policy scheduler with multiple production environments
    Given input claim is changed with parameters
      | param name                                  | param value |
      | spec.resources.productionEnvironments[0]  | prod        |
      | spec.resources.productionEnvironments[1]  | production  |
      | spec.resources.productionEnvironments[2]  | live        |
      | spec.resources.productionEnvironments[3]  | staging     |
    When crossplane renders the composition
    Then check that 6 resources are provisioning

  @major
  Scenario: Policy scheduler with extensive restricted actions
    Given input claim is changed with parameters
      | param name                              | param value               |
      | spec.resources.restrictedActions[0]    | ec2:TerminateInstances    |
      | spec.resources.restrictedActions[1]    | rds:DeleteDBInstance      |
      | spec.resources.restrictedActions[2]    | s3:DeleteBucket          |
      | spec.resources.restrictedActions[3]    | lambda:DeleteFunction     |
      | spec.resources.restrictedActions[4]    | cloudformation:DeleteStack|
    When crossplane renders the composition
    Then check that 6 resources are provisioning

  @minor
  Scenario: Policy scheduler with custom description and names
    Given input claim is changed with parameters
      | param name          | param value                                    |
      | spec.roleName      | custom-time-restricted-role                    |
      | spec.policyName    | custom-time-restricted-policy                  |
      | spec.description   | Custom time-based access for development team |
    When crossplane renders the composition
    Then check that resource production-role has parameters
      | param name                     | param value                                    |
      | spec.forProvider.name         | custom-time-restricted-role                    |
      | spec.forProvider.description  | Custom time-based access for development team |
    And check that resource production-policy has parameters
      | param name                     | param value                       |
      | spec.forProvider.name         | custom-time-restricted-policy     |

  @critical
  Scenario: Verify resource dependencies and ordering
    When crossplane renders the composition
    Then check that 6 resources are provisioning
    Given change observed resource production-role with status READY
    And change observed resource production-role with parameters
      | param name              | param value                                      |
      | status.atProvider.arn  | arn:aws:iam::123456789012:role/test-prod-role    |
    And change observed resource production-policy with status READY  
    And change observed resource production-policy with parameters
      | param name              | param value                                        |
      | status.atProvider.arn  | arn:aws:iam::123456789012:policy/test-prod-policy  |
    When crossplane renders the composition
    Then check that 6 resources are provisioning
    And check that resource policy-attachment has parameters
      | param name                                          | param value |
      | spec.forProvider.roleSelector.matchControllerRef   | true        |
      | spec.forProvider.policyArnSelector.matchControllerRef | true     |

  @major
  Scenario: Lambda function with all environment variables configured
    Given input claim is changed with parameters
      | param name               | param value      |
      | spec.timeWindow.start   | 08:30            |
      | spec.timeWindow.end     | 17:30            |
      | spec.timeWindow.timezone| Europe/London    |
    When crossplane renders the composition
    Then check that resource scheduler-lambda has parameters
      | param name                                         | param value   |
      | spec.forProvider.environment.variables.START_TIME | 08:30         |
      | spec.forProvider.environment.variables.END_TIME   | 17:30         |
      | spec.forProvider.environment.variables.TIMEZONE   | Europe/London |

  @critical
  Scenario: All resources maintain proper tagging
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
    And check that resource scheduler-event-rule has parameters
      | param name                        | param value      |
      | spec.forProvider.tags.Environment| production       |

  @major
  Scenario: CloudWatch Event Rule with different schedule intervals
    Given input claim is changed with parameters
      | param name             | param value  |
      | spec.schedule.interval | 2 hours      |
    When crossplane renders the composition
    Then check that resource scheduler-event-rule has parameters
      | param name                           | param value    |
      | spec.forProvider.scheduleExpression  | rate(2 hours)  |
      | spec.forProvider.state              | ENABLED        |

  @minor
  Scenario: Verify Lambda permission configuration
    When crossplane renders the composition
    Then check that resource lambda-permission has parameters
      | param name                                             | param value                            |
      | spec.forProvider.action                               | lambda:InvokeFunction                  |
      | spec.forProvider.principal                            | events.amazonaws.com                   |
      | spec.forProvider.functionNameSelector.matchControllerRef | true                                |
      | spec.forProvider.sourceArnSelector.matchControllerRef    | true                                |

  @critical
  Scenario: Full integration test with all observed resources ready
    When crossplane renders the composition
    Then check that 6 resources are provisioning
    Given change all observed resources with status READY
    And change observed resource production-role with parameters
      | param name              | param value                                      |
      | status.atProvider.arn  | arn:aws:iam::123456789012:role/full-test-role    |
    And change observed resource production-policy with parameters
      | param name              | param value                                        |
      | status.atProvider.arn  | arn:aws:iam::123456789012:policy/full-test-policy  |
    And change observed resource scheduler-lambda with parameters
      | param name                        | param value                                           |
      | status.atProvider.functionName   | full-test-scheduler-function                          |
      | status.atProvider.arn           | arn:aws:lambda:us-east-1:123456789012:function:full-test |
    And change observed resource scheduler-event-rule with parameters
      | param name              | param value                                        |
      | status.atProvider.arn  | arn:aws:events:us-east-1:123456789012:rule/full-test-rule |
    When crossplane renders the composition
    Then check that 6 resources are provisioning and they are
      | resource-name             |
      | production-role           |
      | production-policy         |
      | policy-attachment         |
      | scheduler-lambda          |
      | scheduler-event-rule      |
      | lambda-permission         |