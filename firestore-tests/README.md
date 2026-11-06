# Firestore security-rules tests

Exercises `../firestore.rules` against the Firestore emulator. Nothing here
touches the live project.

## Run

```bash
cd firestore-tests
npm install
npm test
```

`npm test` starts the emulator, runs the suite, and shuts the emulator down.
It needs Node 18+, a JDK (the emulator is a Java process), and
`firebase-tools` available (`npx firebase` works, or install it globally).

The emulator ports come from `../firebase.json`.
