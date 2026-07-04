import QtQuick
import QtQuick.Layouts

// ============================================================
//  2D 频谱可视化 —— 使用 Canvas 绘制圆角柱状频谱
//  从 AppModel.spectrumData 获取频率数据
//  每根柱子使用渐变色 + 圆角顶 + 底部发光
// ============================================================

Canvas {
    id: canvas
    anchors.fill: parent
    opacity: 0.6
    z: 0  // 放在最底层

    // 每 80ms 刷新一次（由 AppModel 的频谱定时器驱动）
    Timer {
        interval: 80
        running: AppModel.playing && AppModel.visualizerMode === "2d"
        repeat: true
        onTriggered: canvas.requestPaint()
    }

    // 颜色渐变用的 HSL 值（从主题色计算）
    function hexToRgb(hex) {
        var c = hex.replace("#", "")
        return {
            r: parseInt(c.substring(0, 2), 16) || 99,
            g: parseInt(c.substring(2, 4), 16) || 102,
            b: parseInt(c.substring(4, 6), 16) || 241
        }
    }

    onPaint: {
        var ctx = getContext("2d")
        var data = AppModel.spectrumData
        if (!data || data.length === 0) return

        ctx.clearRect(0, 0, width, height)

        var barCount = data.length
        var barWidth = width / barCount
        var accent = hexToRgb(mainWindow.accentColor)
        var cornerRadius = Math.min(4, barWidth * 0.3)

        for (var i = 0; i < barCount; i++) {
            var value = data[i] || 0
            var barHeight = (value / 255) * height * 0.65
            var x = i * barWidth + 1
            var y = height - barHeight
            var w = Math.max(2, barWidth - 3)

            // 从深色渐变到亮色
            var t = (i / barCount)  // 从左到右渐变微调
            var alpha = 0.3 + (value / 255) * 0.5
            var lightness = 0.4 + (value / 255) * 0.6

            var r = Math.min(255, Math.round(accent.r * lightness * (0.8 + t * 0.4)))
            var g = Math.min(255, Math.round(accent.g * lightness * (0.8 + t * 0.4)))
            var b = Math.min(255, Math.round(accent.b * lightness * (0.8 + t * 0.4)))

            // 底部更亮的渐变发光
            var r2 = Math.min(255, Math.round(r * 1.3))
            var g2 = Math.min(255, Math.round(g * 1.3))
            var b2 = Math.min(255, Math.round(b * 1.3))

            // 垂直渐变填充
            var grad = ctx.createLinearGradient(x, y, x, height)
            grad.addColorStop(0, "rgba(" + r2 + "," + g2 + "," + b2 + "," + alpha + ")")
            grad.addColorStop(0.4, "rgba(" + r + "," + g + "," + b + "," + alpha + ")")
            grad.addColorStop(1, "rgba(" + Math.round(r*0.3) + "," + Math.round(g*0.3) + "," + Math.round(b*0.3) + "," + (alpha * 0.3) + ")")

            // 画圆角矩形
            ctx.fillStyle = grad
            ctx.beginPath()
            ctx.moveTo(x + cornerRadius, y)
            ctx.lineTo(x + w - cornerRadius, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + cornerRadius)
            ctx.lineTo(x + w, height)
            ctx.lineTo(x, height)
            ctx.lineTo(x, y + cornerRadius)
            ctx.quadraticCurveTo(x, y, x + cornerRadius, y)
            ctx.closePath()
            ctx.fill()
        }
    }
}
