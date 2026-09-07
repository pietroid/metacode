# Project Structure

## 1. Metacode engine

Metacode Engine is the Go Program that takes care of everything on metacode. In this repository, it should live inside engine/ and down there it will be a regular go project.

## 2. Metacode project

A metacode project is a project that actually uses metacode. For now, it's a simple Flutter project. For this repository, we will have a examples/ folder and a set of sample projects. 

Let's consider what the folder hierarchy looks like and what each of the things do in a Metacode Project.

```
metacode/
├── examples/
│   ├── counter_app
│   │   ├── pubspec.yaml # It's a regular flutter app
│   │   ├── metacode # but has a extra metacode folder inside it.
│   │   │   ├── ui.yaml
│   │   │   ├── behaviors.yaml
│   │   │   ├── data.yaml
│   │   │   ├── project.yaml
│   │   │   ├── .lock # Lock uses the past versions of specs to store it and have a diff.
│   │   │   │     ├── lock.yaml # lock.yaml specs
│   │   │   │     ├── ui.yaml
│   │   │   │     ├── behaviors.yaml
│   │   │   │     ├── data.yaml
│   │   │   │     └── project.yaml
├── ├── finance_app
│    ....
```

When running `metacode run` inside a project, it locates the metacode folder and runs with the data inside it.