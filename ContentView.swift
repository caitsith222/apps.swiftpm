import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()

            Button(action: {
                print("OK button tapped")
            }) {
                Text("OK")
                    .font(.title)
                    .padding()
                    .frame(width: 120)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()
        }
    }
}
