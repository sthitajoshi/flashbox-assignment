const test = require("node:test");
const assert = require("node:assert/strict");
const app = require("./server");

test("API app exports an Express application", () => {
  assert.equal(typeof app, "function");
  assert.equal(typeof app.get, "function");
});
