function proj = projectfile(buildOption, projectName, codeFolders, opts)
   %PROJECTFILE File to create a matlab project.
   %
   % proj = projectfile('MyProject', 'toolbox') creates a new project called
   % MyProject.prj and adds all files in the toolbox/ directory to the project.
   % Files in the top level directory are not added to the project.
   %
   % projectfile('resolve', 'depsFolder', 'toolbox/+tbx/private') copies all
   % missing dependencies to toolbox/+tbx/private/. Use this prior to packaging
   % the toolbox for release, so all files are available.
   %
   % See also: buildfile, setupfile

   % Define the options to add folders and files

   % Parse the option
   arguments
      buildOption (1,:) string {mustBeMember(buildOption, ...
         ["create", "delete", "update", "resolve"])} = "create"
      projectName (1,1) string = string(NaN)
      codeFolders (:,1) string = string(NaN)
      opts.depsFolder (1,1) string = string(NaN)
      opts.addCodeFiles (1,1) logical = true;
      opts.addProjectFiles (1,1) logical = false;
   end

   % Define the main project folder
   projectFolder = fileparts(mfilename('fullpath'));

   % Define the project name
   if ismissing(projectName)
      [~, projectName] = fileparts(projectFolder);
   end

   % Define the sub folders to add to the project
   if ismissing(codeFolders)

      if isfolder(fullfile(projectFolder, 'toolbox'))
         codeFolders = "toolbox";
      else
         error(['No toolbox/ directory found.' newline ...
            'To specify which folders to add to the project, try:' newline ...
            'makeproject(projectname, toolboxfolders)'])
      end
   end

   switch buildOption

      case 'delete'
         % Delete the project
         try
            matlab.project.deleteProject(projectFolder);
         catch
         end
         return

      case 'create'
         % Create the project
         proj = createMatlabProject(projectFolder, opts.addProjectFiles, ...
            opts.addCodeFiles, codeFolders, projectName);

      case 'resolve'
         % Resolve dependencies
         resolveDependencies(projectFolder, opts.depsFolder)
   end
end

%% subfunctions
function resolveDependencies(projectFolder, depsFolder)

   depsFolder = fullfile(projectFolder, depsFolder);
   if ~isfolder(depsFolder)
      mkdir(depsFolder)
   end

   wasProjectOpen = true;
   try
      projectObj = currentProject;
   catch
      wasProjectOpen = false;
      projectObj = openProject(projectFolder);
   end

   projectFiles = [projectObj.Files.Path].';
   requiredFiles = listRequiredFiles(projectObj, projectFiles);
   missingFiles = setdiff(requiredFiles, projectFiles);

   for srcfile = missingFiles'
      [~, filename, fext] = fileparts(srcfile);
      dstfile = fullfile(depsFolder, strcat(filename, fext));
      copyfile(srcfile, dstfile);
      addFile(projectObj, dstfile);
   end

   updateDependencies(projectObj);

   if ~wasProjectOpen
      close(currentProject);
   end
end

%%
function mustBeValidOption(option)
   % To use this, add this back to the arguments block:
   % buildOption (1, 1) char {mustBeValidOption(buildOption)} = 'create'

   % Test for membership in list
   validopts = {'create', 'delete', 'update', 'resolvedeps'};
   if ~ismember(option, validopts)
      eid = 'Option:notValid';
      msg = 'Input option must be ''add'' or ''multiply''.';
      throwAsCaller(MException(eid,msg))
   end
end
% This is from teh delete project section. It is based on my initial attempts to
% create a project programmatically in icom-msd project create_matlab_project
% script where I had to close it first b/c I had just created it, but I am not
% acutally sure it has to be closed.
%    try
%       projectRootFolder = currentProject().RootFolder;
%    catch e
%       if strcmp(e.message, 'No project is currently loaded.')
%          openProject(projectFolder)
%          projectRootFolder = currentProject().RootFolder;
%       end
%    end
%    close(currentProject); matlab.project.deleteProject(projectRootFolder);
%    return
