import SwiftUI

struct NoDeviceConnectedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Device Connected")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Please connect to an acoustic camera device from the Connect tab before using the controls.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding()
            
            NavigationLink(destination: DeviceConnectionView()) {
                Text("Go to Connect")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}