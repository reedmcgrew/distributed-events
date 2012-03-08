# You can use this command to watch all source files for changes,
# running the test_runner whenever a change is detected
# You must have nodemon installed for this to work: sudo npm install -g nodemon
nodemon --watch test_runner.coffee --watch test --watch src test_runner.coffee
