# Requirements Spec

Requirements Spec is the cornerstone of Metacode. 

As they are very abstract and can apply for a variety of scenarios to cover all the complexity of covering the behavior of the system, we need to consider more carefully some design decisions:

- Requirements are not meant to be necessarily integration tests nor strictly unit tests (ie, describing each separate implementation class/layer). They are solely meant to cover the behaviors of the system.

- Requirements should cover the minimal surface of the existing structures. For example, if we require the counter to increment on button tap, the requirement should not focus on the internal naming or the implementation of the event to increment, it should just cover the surface (input/output), which means the event from the button and the outcome of the store.

- Requirements should be enough for describing all the behaviors of the system. This one is an interesting statement, as it reflects the main philosophy of metacode. It can't figure out some behavior you haven't given to the system. For example, if you don't tie the store to the UI, it will not reflect that on the generated code. If you don't consider exceptions, this will also not be covered in the code. This is not a flaw of the system, but a design decision, the requirements spec is so important that you must give yourself time and dedication to really understand if they are enough for your system.

## Syntax

Requirements have a regular, determinstic syntax. 

### Scenario

The unit of requirements is a scenario. A scenario is built like this:

```yaml
When counterButton is pressed, it should increment the counter:
    given: counterStore.value is 5
    when: counterButton.onPressed
    then: counterStore.value should be 6
```

The key is a text free description. It will affect nothing on the code itself, but is important to be well described as both a human document and a way to guide AI to reach the goal of that scenario.

The core of the determinstic behavior to be tested is on the next three lines.

1. Given: It's the condition of any of the variables of that certain scenario. In the example, value is a known value from counterStore
2. When: It's an event triggered from any function
3. Then: It's the action or value a variable should assume.

_Notice that scenarios are concrete, specific. If we want to cover more cases in a structured way, that's where grouping comes in_

### Grouping

Grouping is very simple, we replace it by a list of keys that will also contain a free text description.

```yaml
When counterButton is pressed, it should increment the counter:
    - case for 0:
        given: counterStore.value is 0
        when: counterButton.onPressed
        then: counterStore.value should be 1
    - case for 1:
        given: counterStore.value is 1
        when: counterButton.onPressed
        then: counterStore.value should be 2
    - case for 2:
        given: counterStore.value is 2
        when: counterButton.onPressed
        then: counterStore.value should be 3
```

It can be nested infinitely:

```yaml
Renders the correct color based on the percentage:
    - for less than 30%:
        - 0% case:
            given: value is 0
            then: color should be red
        - 29% case:
            given: value is 0.29
            then: color should be red
    - between 30% and 60%:
        - 30% case:
            given: value is 0.3
            then: color should be yellow
        - 59% case:
            given: value is 0.59
            then: color should be yellow
    - for more than 60%:
        - 60% case:
            given: value is 0.6
            then: color should be green
        - 100% case:
            given: value is 1
            then: color should be green
```