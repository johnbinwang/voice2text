import SwiftUI

struct WaveformView: View {
    let rmsLevel: Float

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<Constants.waveformBarCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 4, height: barHeight(for: index))
            }
        }
        .frame(width: Constants.waveformWidth, height: Constants.waveformHeight)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let weight = Constants.waveformBarWeights[index]
        let jitter = CGFloat.random(in: -Constants.waveformJitterAmount...Constants.waveformJitterAmount)
        let adjustedLevel = CGFloat(rmsLevel) * weight * (1 + jitter)
        let minHeight: CGFloat = 4
        let maxHeight = Constants.waveformHeight
        return minHeight + (maxHeight - minHeight) * adjustedLevel
    }
}
