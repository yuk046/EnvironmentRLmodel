# Java port of run_batch_beta

This project is a Java (Maven) scaffold to port `run_batch_beta.m` and its dependencies from MATLAB to Java.

Goals
- Provide an object-oriented structure: Environment, EpisodeRunner, BatchRunner, Result.
- Produce JSON results in `data/` folder similar to MATLAB `results_beta_*.mat` (initially JSON).

Build

```bash
cd "${WORKSPACE}/java_rl"
mvn -q -DskipTests package
```

Run (example)

```bash
java -jar target/java-rl-0.1.0-jar-with-dependencies.jar
```

Notes
- This initial commit implements Environment creation and a simple EpisodeRunner that runs random actions to validate the pipeline.
- Next steps: port `step`, `CreateModel`, `DP`, `Episode_WithReset_And_Statistics` logic and MF/MB policies.
