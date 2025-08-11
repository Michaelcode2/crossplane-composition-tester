### Composition.yml requirements:

        template: |-
          {{/* TODO: implement the composition with one or more steps. The function can be any function from https://github.com/crossplane-contrib?q=function or custom one. Explain your choice. */}}
          {{/* TODO: the composition must: */}}
          {{/*  1. handle all schedules from the schedules list */}}
          {{/*  2. for each schedule: provision the role and assign the policy ONLY during the time interval specified by the scheduleFrom and scheduleUntil */}}
          {{/* TODO: write composition tests to demonstrate how the composition functions; write as many relevant tests as you consider. Justify the choices made! */}}
          {{/* HINT 1: Make use of tags to run a sub set of tests. For example: ./tests_runner.sh test -t PolicyScheduler -t normal */}}
          {{/* HINT 2: Make use of debug flag to get the observed and desired states of each crossplane iteration. Check ./dump folder. For example: ./tests_runner.sh test -d */}}

