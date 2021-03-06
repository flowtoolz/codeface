import SwiftUI
import SwiftObserver

class CodefaceView: NSHostingView<ContentView>
{
    init() { super.init(rootView: ContentView()) }
    
    required init(rootView: ContentView) { super.init(rootView: rootView) }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) { nil }
}

struct Preview: PreviewProvider
{
    static var previews: some View
    {
        ContentView().previewDisplayName("ContentView")
    }
}

struct ContentView: View
{
    var body: some View
    {
        NavigationView
        {
            List(viewModel.artifacts, id: \.id, children: \.children)
            {
                artifact in
                
                Image(systemName: systemName(for: artifact.kind))
                Text(artifact.displayName)
            }
            .listStyle(SidebarListStyle())
            
            Text("Huhu")
        }
    }
    
    private func systemName(for articactKind: CodeArtifact.Kind) -> String
    {
        switch articactKind
        {
        case .folder: return "folder"
        case .file: return "doc"
        }
    }
    
    @ObservedObject private var viewModel = ContentViewModel()
}

private class ContentViewModel: ObservableObject, Observer
{
    init()
    {
        observe(Project.messenger)
        {
            switch $0
            {
            case .didSetActiveProject(let activeProject):
                if let activeProject = activeProject
                {
                    self.artifacts = [CodeArtifact(folder: activeProject.rootFolder)]
                }
                else
                {
                    self.artifacts = []
                }
            }
        }
    }
    
    @Published var artifacts = [CodeArtifact]()
    
    let receiver = Receiver()
}
 
class CodeArtifact
{
    convenience init(folder: CodeFolder)
    {
        var childArtifacts = [CodeArtifact]()
        
        childArtifacts += folder.files.map(CodeArtifact.init)
        childArtifacts += folder.subfolders.map(CodeArtifact.init)
        
        self.init(displayName: folder.name,
                  kind: .folder,
                  children: childArtifacts.isEmpty ? nil : childArtifacts)
    }
    
    convenience init(codeFile: CodeFolder.File)
    {
        self.init(displayName: codeFile.name, kind: .file)
    }
    
    init(displayName: String, kind: Kind, children: [CodeArtifact]? = nil)
    {
        self.displayName = displayName
        self.kind = kind
        self.children = children
    }
    
    let id = UUID().uuidString
    let displayName: String
    let kind: Kind
    let children: [CodeArtifact]?
    
    enum Kind { case folder, file }
}
