module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverageFrom: [
    'controllers/**/*.js',
    'middleware/**/*.js',
    'routes/**/*.js',
  ],
  coveragePathIgnorePatterns: ['/node_modules/'],
  testTimeout: 10000,
  detectOpenHandles: true,
  forceExit: true,
};
