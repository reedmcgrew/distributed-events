nodeunit = require('nodeunit').reporters.default
# Run Tests
now = new Date()
console.log "Running tests"
process.chdir __dirname
nodeunit.run ['./test']
