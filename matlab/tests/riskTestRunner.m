function result = riskTestRunner(doProfiling)
%RISKTESTRUNNER runs the unit tests which are located in /tests

if nargin==0, doProfiling = 0; end

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import marietta.*;

rd = which('valueAtRisk.m');
toks = strsplit(rd, 'valueAtRisk.m');
warning on
folderTests = fullfile(toks{1},'tests');
suite = TestSuite.fromFolder(folderTests);

runner = TestRunner.withTextOutput;
if doProfiling
    import matlab.unittest.plugins.CodeCoveragePlugin
    runner.addPlugin(CodeCoveragePlugin.forFolder('./+marietta'))
end
result = runner.run(suite);
disp(result.table)

