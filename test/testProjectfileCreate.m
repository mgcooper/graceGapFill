classdef testProjectfileCreate < matlab.unittest.TestCase
   %TESTPROJECTFILECREATE Regression test for the projectfile create path.
   %
   % Pins the call-site argument order against the vendored
   % createMatlabProject signature (matfunclib-juq.28): the stale
   % positional order crashed on argument validation before any project
   % was created. The test runs the create path in a temp copy, because
   % projectfile('create') mutates Project state in its own folder and
   % the repository already carries a project file.

   properties
      sandbox string
   end

   methods (TestClassSetup)
      function addProjectToPath(testCase)
         %ADDPROJECTTOPATH Put the repository root on the path.
         % The test locates the files it copies into the sandbox relative
         % to the repository root.
         import matlab.unittest.fixtures.PathFixture
         testFile = mfilename("fullpath");
         testFolder = fileparts(testFile);
         projectFolder = fileparts(testFolder);
         testCase.applyFixture(PathFixture(projectFolder));
      end
   end

   methods (TestMethodSetup)
      function buildSandbox(testCase)
         %BUILDSANDBOX Stage a temp copy of the create-path files.
         % Copy projectfile.m, its vendored createMatlabProject, and a
         % minimal toolbox/ folder into a temp sandbox, then cd there so
         % the copies resolve first (the current folder wins name
         % resolution). The teardown returns to the start folder before
         % the fixture deletes the sandbox.
         import matlab.unittest.fixtures.TemporaryFolderFixture
         tmp = testCase.applyFixture(TemporaryFolderFixture);
         testCase.sandbox = string(tmp.Folder);

         testFolder = fileparts(mfilename("fullpath"));
         repoRoot = fileparts(testFolder);
         copyfile(fullfile(repoRoot, "projectfile.m"), testCase.sandbox);
         copyfile(fullfile(repoRoot, "toolbox", "code", "dependencies", ...
            "createMatlabProject.m"), testCase.sandbox);
         mkdir(fullfile(testCase.sandbox, "toolbox"))
         fid = fopen(fullfile(testCase.sandbox, "toolbox", "stubfun.m"), 'w');
         fprintf(fid, '%% stub file so the project has one member\n');
         fclose(fid);

         startdir = pwd();
         testCase.addTeardown(@() cd(startdir))
         cd(testCase.sandbox);
      end
   end

   methods (Test)
      function testCreateCompletesAndWritesProject(testCase)
         % The corrected positional order must pass argument validation
         % and produce a project file; the juq.28 defect (stale positional
         % order) errored inside createMatlabProject before any .prj
         % existed.
         proj = projectfile('create');
         % Close before teardown so the fixture can delete the sandbox.
         testCase.addTeardown(@() close(proj))

         prjfiles = dir(fullfile(testCase.sandbox, '*.prj'));
         testCase.verifyNumElements(prjfiles, 1);
         % The project takes the sandbox folder name, which createProject
         % capitalizes; compare case-insensitively.
         [~, folderName] = fileparts(char(testCase.sandbox));
         % char() both sides: proj.Name is a string, folderName a char.
         returned = lower(char(proj.Name));
         expected = lower(folderName);
         testCase.verifyEqual(returned, expected);
         % The toolbox code folder must enter the project: the create call
         % must enable the vendored folder-adding branch, or the project
         % comes out empty.
         memberPaths = string({proj.Files.Path});
         hasStub = any(endsWith(memberPaths, ...
            fullfile("toolbox", "stubfun.m")));
         testCase.verifyTrue(hasStub);
      end
   end
end
