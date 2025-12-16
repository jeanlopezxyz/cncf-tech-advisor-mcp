#!/usr/bin/env node

// =============================================================================
// CNCF Tech Advisor MCP - Test Script
// =============================================================================
// Simple test to verify the NPM package structure is working
// Usage: node test/test.js
// =============================================================================

const assert = require('assert');
const path = require('path');
const fs = require('fs');

console.log('🧪 Testing CNCF Tech Advisor MCP package structure...');

// Test 1: Check if main files exist
console.log('\n📁 Checking package structure...');

const packageJsonPath = path.join(__dirname, '../npm/cncf-tech-advisor/package.json');
const binIndexPath = path.join(__dirname, '../npm/cncf-tech-advisor/bin/index.js');
const readmePath = path.join(__dirname, '../npm/cncf-tech-advisor/README.md');

assert(fs.existsSync(packageJsonPath), 'package.json should exist');
assert(fs.existsSync(binIndexPath), 'bin/index.js should exist');
assert(fs.existsSync(readmePath), 'README.md should exist');

console.log('✅ Main package files exist');

// Test 2: Check package.json structure
console.log('\n📄 Checking package.json structure...');
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

assert(packageJson.name === 'cncf-tech-advisor', 'Package name should be correct');
assert(packageJson.version === '1.0.0', 'Package version should be correct');
assert(packageJson.bin['cncf-tech-advisor'] === './bin/index.js', 'Binary path should be correct');
assert(packageJson.optionalDependencies, 'Should have optionalDependencies');
assert(packageJson.engines.node === '>=16', 'Node.js version requirement should be specified');

console.log('✅ package.json structure is correct');

// Test 3: Check binary wrapper
console.log('\n🔧 Checking binary wrapper...');
const binContent = fs.readFileSync(binIndexPath, 'utf8');

assert(binContent.includes('#!/usr/bin/env node'), 'Should have node shebang');
assert(binContent.includes('BINARY_MAP'), 'Should have binary mapping');
assert(binContent.includes('cncf-tech-advisor-darwin-arm64'), 'Should include macOS ARM64 binary');
assert(binContent.includes('cncf-tech-advisor-darwin-x64'), 'Should include macOS x64 binary');
assert(binContent.includes('cncf-tech-advisor-linux-x64'), 'Should include Linux x64 binary');
assert(binContent.includes('cncf-tech-advisor-windows-x64'), 'Should include Windows x64 binary');

console.log('✅ Binary wrapper is correct');

// Test 4: Check README
console.log('\n📖 Checking README.md...');
const readmeContent = fs.readFileSync(readmePath, 'utf8');

assert(readmeContent.includes('cncf-tech-advisor'), 'Should contain package name');
assert(readmeContent.includes('npx cncf-tech-advisor@latest'), 'Should contain installation command');
assert(readmeContent.includes('MCP Server for CNCF Landscape'), 'Should contain description');

console.log('✅ README.md is correct');

// Test 5: Check Dockerfile
console.log('\n🐳 Checking Dockerfile...');
const dockerfilePath = path.join(__dirname, '../Dockerfile');

if (fs.existsSync(dockerfilePath)) {
    const dockerfileContent = fs.readFileSync(dockerfilePath, 'utf8');

    assert(dockerfileContent.includes('quay.io/quarkus/ubi-quarkus-mandrel-builder-image'), 'Should use Mandrel builder');
    assert(dockerfileContent.includes('quay.io/quarkus/ubi9-quarkus-micro-image'), 'Should use micro image');
    assert(dockerfileContent.includes('-Dnative'), 'Should build native executable');

    console.log('✅ Dockerfile is correct');
} else {
    console.log('⚠️ Dockerfile not found (skipping)');
}

// Test 6: Check build scripts
console.log('\n🔨 Checking build scripts...');
const buildScriptPath = path.join(__dirname, '../scripts/build-npm.sh');
const crossBuildScriptPath = path.join(__dirname, '../scripts/cross-build.sh');

if (fs.existsSync(buildScriptPath)) {
    assert(fs.statSync(buildScriptPath).mode & fs.constants.S_IXUSR, 'build-npm.sh should be executable');
    console.log('✅ build-npm.sh exists and is executable');
} else {
    console.log('⚠️ build-npm.sh not found (skipping)');
}

if (fs.existsSync(crossBuildScriptPath)) {
    assert(fs.statSync(crossBuildScriptPath).mode & fs.constants.S_IXUSR, 'cross-build.sh should be executable');
    console.log('✅ cross-build.sh exists and is executable');
} else {
    console.log('⚠️ cross-build.sh not found (skipping)');
}

// Test 7: Check Java project structure
console.log('\n☕ Checking Java project structure...');
const pomPath = path.join(__dirname, '../pom.xml');
const mainSrcPath = path.join(__dirname, '../src/main/java/io/mcp/cncf');

if (fs.existsSync(pomPath)) {
    const pomContent = fs.readFileSync(pomPath, 'utf8');
    assert(pomContent.includes('quarkus-mcp-server'), 'Should include MCP server dependencies');
    assert(pomContent.includes('<id>native</id>'), 'Should have native profile');

    console.log('✅ Maven project structure is correct');

    if (fs.existsSync(mainSrcPath)) {
        const javaFiles = fs.readdirSync(mainSrcPath);
        const expectedDirs = ['tool', 'service', 'client', 'model'];

        for (const dir of expectedDirs) {
            if (fs.existsSync(path.join(mainSrcPath, dir))) {
                console.log(`  ✅ ${dir}/ directory exists`);
            }
        }
    }
} else {
    console.log('⚠️ pom.xml not found (skipping Java checks)');
}

console.log('\n🎉 All tests passed!');
console.log('\n📋 Next steps:');
console.log('   1. Build the project: ./scripts/build-npm.sh');
console.log('   2. Test the MCP server: java -jar target/quarkus-app/quarkus-run.jar');
console.log('   3. Build native executable: ./mvnw package -Dnative');
console.log('   4. Publish to NPM: cd npm-dist && npm publish');
console.log('\n✨ CNCF Tech Advisor MCP is ready for distribution!');