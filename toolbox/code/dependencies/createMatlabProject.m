function varargout = createMatlabProject(projectFolder, projectName, ...
      addProjectFiles, addProjectFolders, addChildFiles, projectSubfolders, ...
      ignoredSubFolders)
   %CREATEMATLABPROJECT Create a new MATLAB project.
   %
   %    proj = createMatlabProject(projectFolder, projectName, ...
   %       addProjectFiles, addProjectFolders, addChildFiles, ...
   %       projectSubfolders, ignoredSubFolders)
   %
   % Description
   %
   %  This function creates a new MATLAB project, adds files and/or folders in
   %  the projectFolder to the project, and recursively adds files from all
   %  projectSubfolders if addChildFiles is true. Finally, it updates the
   %  dependencies of the project.
   %
   % Inputs (all optional)
   %
   %  PROJECTFOLDER - The parent (top level) project folder (scalar text). Can
   %  be a full path or name from which the full path is constructed using the
   %  MATLABPROJECTPATH environment variable. The default is pwd().
   %
   %  PROJECTNAME - Scalar text used for the .prj filename. If not provided, the
   %  PROJECTFOLDER folder name is used for PROJECTNAME. The .prj filename is
   %  constructed automatically by the function matlab.project.createProject,
   %  which capitalizes the first letter only, for instance, <Projectname>.prj.
   %  Thus if PROJECTFOLDER="/path/to/my/awesomeproject", and PROJECTNAME is not
   %  supplied, PROJECTNAME will be "awesomeproject", and the .prj file will be
   %  Awesomeproject.prj. Provide a value for PROJECTNAME to use an alternative
   %  such as CamelCase: <AwesomeProjectName>.prj. The default is PROJECTFOLDER.
   %
   %  ADDPROJECTFILES - Flag (logical scalar) to control if all files in the
   %  top-level PROJECTFOLDER are added to the project. The default is false.
   %
   %  ADDPROJECTFOLDERS - Flag (logical scalar) to control if all folders in the
   %  top-level PROJECTFOLDER are added to the project. Note that files within
   %  these folders are not added unless ADDCHILDFILES is true. The default is
   %  false.
   %
   %  ADDCHILDFILES - Flag (logical scalar) to control if all files in
   %  PROJECTFOLDER and PROJECTSUBFOLDERS are recursively added to the project.
   %  The default is false.
   %
   %  PROJECTSUBFOLDERS - String array specifying which subfolders of
   %  PROJECTFOLDER should be added to the project. If ADDPROJECTFILES is false,
   %  but ADDCHILDFILES is true and PROJECTSUBFOLDERS is not empty, then all
   %  PROJECTSUBFOLDERS and files within them are added to the project,
   %  regardless of the value of ADDPROJECTFOLDERS (which is specific to how the
   %  top-level folders/files are treated). Use this to ignore certain files
   %  and/or folders in the top level of a project (such as LICENSE or any other
   %  file), instead restricting project-managed files to a subfolder, such as a
   %  toolbox/ folder. The default is an empty string.
   %
   %  IGNOREDSUBFOLDERS - String array of subfolders within PROJECTFOLDER to be
   %  ignored when adding folders and files to the project. Use this to
   %  selectively ignore certain folders such as those ignored by your version
   %  control system.
   %
   % Outputs
   %
   %  PROJ: The MATLAB project object.
   %
   % See also: projectfile

   % TODO: 
   % - args need to be name-value.
   % - option to add folders to project path, see "addPath" function

   arguments
      projectFolder (1,1) string {mustBeFolder} = pwd()
      projectName string = string(NaN)
      addProjectFiles (1, 1) logical = false
      addProjectFolders (1, 1) logical = false
      addChildFiles (1, 1) logical = false
      projectSubfolders (:,1) string = string(NaN)
      ignoredSubFolders (1, :) string = ""
   end

   if isempty(projectName) || ismissing(projectName)
      [~, projectName, ~] = fileparts(projectFolder);
      projectName = string(projectName);
   end

   defaultIgnore = [".git",".svn","resources"];
   if isempty(ignoredSubFolders)
      ignoredSubFolders = defaultIgnore;
   else
      ignoredSubFolders = [ignoredSubFolders, defaultIgnore];
   end

   % % This doesn't work b/c the project name is converted to a valid varname %
   % Check if a project with the same name already exists projectPath =
   % fullfile(projectFolder, projectName + ".prj"); if isfile(projectPath)
   %     error("A project with the name '%s' already exists in '%s'.",
   %     projectName, projectFolder)
   % end

   % Get a list of all sub-folders to add to the project. This step is performed
   % first because creating the project generates new folders.
   [projectSubfolders, ~] = getProjectFolders(projectFolder, ...
      projectSubfolders, ignoredSubFolders);

   % Note: the second output of getProjectFolders (projectFiles) is a list of
   % all files in all subfolders, and the top level (I think). It is a cleaner
   % list, but I decided against passing it directly to proj.addFile, instead I
   % use proj.addFolderIncludingChildFiles which achieves the same thing but
   % adds all files e.g. .DS_Store. Overall I think its better this way though
   % b/c Projects want to manage all subfolders and files, and I don't think
   % there's any harm in adding all files. 
   % 
   % However, this was also done to make it easier to only add the toolbox/
   % folder e.g., the following would only add the toolbox/ folder:
   %     addProjectFiles=false
   %     addProjectFolders=false,
   %     addChildFiles=true
   %     projectSubfolders="toolbox"
   % 
   % This is how makeproject/projectfile is configured.

   % Create a new project
   proj = matlab.project.createProject( ...
      "Name", projectName, "Folder", projectFolder);

   % Add all top-level files
   if addProjectFiles
      projectFiles = dir(fullfile(projectFolder, '*.m'));
      projectFiles = fullfile({projectFiles.folder}', {projectFiles.name}');
      cellfun(@(file) proj.addFile(file), projectFiles);
   end

   % Recursively add all files in all projectSubfolders.
   if addProjectFolders

      if addChildFiles
         % Add files in each projectSubfolder and their subfolders.
         cellfun(@(folder) ...
            proj.addFolderIncludingChildFiles(folder), projectSubfolders);
      else
         % Add files in the top-level of each projectSubfolder
         cellfun(@(folder) ...
            proj.addFile(folder), projectSubfolders);
      end
   end

   % Update dependencies
   updateDependencies(proj);

   % Return the project object if requested
   if nargout
      varargout{1} = proj;
   end
end

function [projectSubfolders, projectFiles] = getProjectFolders( ...
      projectFolder, projectSubfolders, ignoreFolders)
   %GETPROJECTFOLDERS Returns a list of subfolders within projectFolder.
   %
   % projectSubfolders: String array. A list of specific subfolders to be
   % included. If this is empty, all subfolders within projectFolder are
   % returned.
   %
   % The function also excludes certain folders like '.git', '.svn', and
   % 'resources' from the returned list.
   %
   % Note: It returns only the subfolders, and 'addFolderIncludingChildFiles'
   % takes care of adding files from these subfolders to the project.

   % Note: I could return all the files, including the top level projectFolder
   % ones, and use addFile on all of them, but for now, I return the subfolders,
   % and addFolderIncludingChildFiles takes care of recursive files.

   % Get all subfolders
   allSubfolders = dir(fullfile(projectFolder, '**/*'));
   allSubfolders(strncmp({allSubfolders.name}, '.', 1)) = [];
   allSubfolders = allSubfolders([allSubfolders.isdir]);

   % Remove .git, .svn, and resources folders.
   allSubfolders = allSubfolders(~contains({allSubfolders.folder},ignoreFolders));
   allSubfolders = allSubfolders(~ismember({allSubfolders.name},ignoreFolders));

   % If no subfolders are specified, use all subfolders (except ignored ones).
   if ismissing(projectSubfolders) || isempty(projectSubfolders)
      projectSubfolders = allSubfolders;
   else
      % Use the specified projectSubfolders
      projectSubfolders = allSubfolders( ...
         ismember({allSubfolders.name}, projectSubfolders));
   end

   % Check if specified subfolders are actual subfolders of the projectFolder
   if ~all(startsWith({projectSubfolders.folder}, projectFolder))
      error('All projectSubfolders must be subfolders of projectFolder.')
   end

   % Remove .git, .svn, and resources folders.
   projectSubfolders = projectSubfolders(~contains( ...
      {projectSubfolders.folder}, ignoreFolders));

   projectSubfolders = projectSubfolders(~ismember( ...
      {projectSubfolders.name}, ignoreFolders));

   % Convert from dir struct to full path.
   projectSubfolders = fullfile( ...
      {projectSubfolders.folder}', {projectSubfolders.name}');

   % Get a list of all files in the project folder.
   if isempty(projectSubfolders)
      % This occurs when the folder has no subfolders. Could generate a list of
      % files in the top level folder, but that's what addProjectFiles is for.
      %
      % projectFiles = dir(fullfile(projectFolder, '*.m'));

      projectFiles = projectSubfolders;
   else

      % The only problem with this is it does not ignore the folders which were
      % removed from projectSubfolders above, but this gets all the files in teh
      % project without calling listfiles. Plus these files aren't even used in
      % the main function.
      projectFiles = dir(fullfile(projectFolder, '**/*'));
      projectFiles(strncmp({projectFiles.name}, '.', 1)) = [];
      projectFiles = projectFiles(~[projectFiles.isdir]);
      projectFiles = fullfile({projectFiles.folder}', {projectFiles.name}');

      % listfiles is the only dependency so use the method above.
      %projectFiles = listfiles(projectSubfolders, "subfolders", true, ...
      %   "aslist", true, "fullpath", true);
   end
end
