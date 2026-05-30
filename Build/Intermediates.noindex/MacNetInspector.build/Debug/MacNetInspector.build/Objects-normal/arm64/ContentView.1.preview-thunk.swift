import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/pavelvolkind/Documents/MacNetInspector/MacNetInspector/ContentView.swift", line: 1)
//
//  ContentView.swift
//  MacNetInspector
//
//  Created by Павел Волкинд on 5/28/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: __designTimeString("#4687_0", fallback: "globe"))
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(__designTimeString("#4687_1", fallback: "Hello, world!"))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
