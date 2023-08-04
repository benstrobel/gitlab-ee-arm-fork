## QA jobs in MR pipelines

To run the QA jobs in MR pipeline, you need to either trigger `Trigger:CE-package` or `Trigger:EE-package` manual jobs.

These two  jobs trigger a child pipeline which packages GitLab and creates an image which the `qa-test` and `qa-test-full-suite-manual` job uses to run tests

The following are the qa jobs which run as a part of MR pipeline
| Environment Variable                          | Description |
| --------------------------------------------- | ----------- |
| `qa-test`                         | This job runs a subset of test as mentioned in [this issue](https://gitlab.com/gitlab-org/distribution/team-tasks/-/issues/1303#we-should-keep) |
| `qa-test-full-suite-manual`                             | This is a manual trigger job which runs the entire suite |
