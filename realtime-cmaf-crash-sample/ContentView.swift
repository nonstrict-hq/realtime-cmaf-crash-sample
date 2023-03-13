//
//  ContentView.swift
//  realtime-cmaf-crash-sample
//
//  Created by Nonstrict on 13/03/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button("Start") {
                Task.detached {
                    let source = SampleBufferSource()
                    let writer = CMAFWriter(dimensions: source.dimensions)
                    source.start { sampleBuffer in
                        writer.append(sampleBuffer)
                    }
                }
            }
        }
        .padding()
    }
}
