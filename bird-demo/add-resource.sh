#!/bin/sh

# Add the resources to the keptn project
# 1. Add the slis for the service
keptn add-resource --project=obe-releases --service=selobe-wind --all-stages --resource=sli.yaml --resourceUri=splunk/sli.yaml
keptn add-resource --project=obe-releases --service=selobe-wind --stage=prd --resource=sli-prod.yaml --resourceUri=splunk/sli.yaml

# 2. Add the SLOs for the service
keptn add-resource --project=obe-releases --service=selobe-wind --all-stages --resource=slo.yaml --resourceUri=slo.yaml
keptn add-resource --project=obe-releases --service=selobe-wind --stage=prd --resource=slo-prod.yaml --resourceUri=slo.yaml

# 3. Add the charts for the service
keptn add-resource --project=obe-releases --service=selobe-wind --all-stages --resource=selobe-wind.tgz --resourceUri=charts/selobe-wind.tgz

# 4. Add the the job-executor config for the service
keptn add-resource --project=obe-releases --service=selobe-wind --all-stages --resource=config.yaml --resourceUri=job/config.yaml
keptn add-resource --project=obe-releases --service=selobe-wind --stage=prd --resource=config-prod.yaml --resourceUri=job/config.yaml

# 5. Add the test file
keptn add-resource --project=obe-releases --service=selobe-wind --all-stages --resource=tester.py --resourceUri=tests/tester.py

---
spec_version: "0.1.0"
comparison:
  compare_with: "single_result"
  include_result_with_score: "pass"
  aggregate_function: avg
objectives:
  - sli: number_of_errors
    displayName: "Number of error raised by the application"
    pass:
      - criteria:
          - "<10"
    warning:
      - criteria:
          - ">=10"
          - "<12"
    fail:
      - criteria:
          - ">=12"

total_score:
  pass: "100%"
  warning: "40%"

---
spec_version: "0.1.0"
comparison:
  compare_with: "single_result"
  include_result_with_score: "pass"
  aggregate_function: avg
objectives:
  - sli: number_of_errors
    displayName: "Number of error raised by the application"
    pass:
      - criteria:
          - "<8"
    warning:
      - criteria:
          - ">=8"
          - "<14"
    fail:
      - criteria:
          - ">=14"

total_score:
  pass: "100%"
  warning: "40%"

  ---
spec_version: "0.1.0"
comparison:
  compare_with: "single_result"
  include_result_with_score: "pass"
  aggregate_function: avg
objectives:
  - sli: number_of_errors
    displayName: "Number of error raised by the application"
    pass:
      - criteria:
          - "<5"
    warning:
      - criteria:
          - ">=5"
          - "<6"
    fail:
      - criteria:
          - ">=6"

total_score:
  pass: "100%"
  warning: "40%"