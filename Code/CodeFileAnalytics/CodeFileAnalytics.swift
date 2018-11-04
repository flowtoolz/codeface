import SwiftyToolz

func warningColor(for linesOfCode: Int) -> Color.System
{
    if linesOfCode < 100 { return .green }
    else if linesOfCode < 200 { return .yellow }
    else if linesOfCode < 300 { return .orange }
    else { return .red }
}

struct CodeFileAnalytics
{
    init(file: CodeFile)
    {
        self.file = file
        self.linesOfCode = file.content.numberOfLines
    }
    
    let file: CodeFile
    let linesOfCode: Int
}

extension String
{
    var numberOfLines: Int
    {
        var result = 0
        
        enumerateLines { _, _ in result += 1 }
        
        return result
    }
}