# Metacode Engine

This describes the engine working.

## Steps

### 1.Specs Parsing

_Goal: parse and verify the structure of the YAML Specs_

1. YAML syntax check: Usually done by YAML libraries.
2. Spec syntax check: each kind of Spec has it specific set of validity rules.
3. Symbol extraction: extract the symbols (names) that will be recognized against existing ones or created.

### 2. Internal representation construction

_Goal: identify symbols, correlate them, classify them_

1. Check symbols against catalog of existing symbols
2. Check validity of symbols (e.g. a certain UI component can have just specific members)
3. Create new symbols and classify them in which context they exist

### 3. Planning

_Goal: plan the order of execution of code and tests generation_

1. Scan each scenario from behaviors and identify what is the location of each of the references (UI, store, etc)
2. Break down scenario into subscenarios according to its unit parts (e.g. if a scenario involves multiple layers break down into unit tests). 
3. Create TBD namings and placeholders. (e.g. a store is needed to be created for a scenario, the naming is TBD).
4. Order the execution of each on the priority: 1. fully deterministic specs. 2. TBDs. 3. Tests generation. 4. Code insertions (connections on top of existing units). 5. AI code generation.

### 4. Execution

_Goal: Actually generate code and test it_

1. Execute the list from the planning based on a set of routines that instructs what should be done in each of the plannning steps.
2. Run all tests.
3. Fix tests until they pass.

## Some implementation notes

### Code conventions

- The engine is highly modularized, with each folder corresponding to the step and each file corresponding to sub-step.
- The code is highly commented
- Have always a main function that call any subfunctions inside the file itself.
- All parts tied to concrete and specific specs/code execution should live inside a separate part from the core logic of the engine, that way we can increase and scale independently.

### Internal representation

- From step 2 (internal representation), we should have very definite objects in the engine that match to their meaning. In this way, we can debug and sort them easily later.
- The planning part should use a very compreehensive set of objects connecting the spec, the program that executes that spec, and any other metadata necessary.

### Layered Architecture

The engine is layered such as:

1. Core part: The common part that encompasses all that is listed above.
2. Modules: Everything related to how actually code is generated, the rules for each kind of spec, the libraries of ui components, etc. should live inside its speficic modules so we can have a kind of "plug and play".

### Logging

Everything is passive to be logged as we want for now a very verbose process, to understand what is happening.

So consider everything that is communicated in any of metacode steps to be captured by the logs. The logger is a centralized class that takes care of spitting that out to the console. For now, it will do for everything.