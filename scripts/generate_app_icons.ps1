param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function New-DegreeLensMasterIcon {
    param(
        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $size = 1024
    $bitmap = [System.Drawing.Bitmap]::new(
        $size,
        $size,
        [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.CompositingQuality =
            [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode =
            [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode =
            [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        $bounds = [System.Drawing.RectangleF]::new(0, 0, $size, $size)
        $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            [System.Drawing.PointF]::new(0, 0),
            [System.Drawing.PointF]::new($size, $size),
            [System.Drawing.Color]::FromArgb(255, 67, 215, 198),
            [System.Drawing.Color]::FromArgb(255, 141, 99, 247)
        )
        $blend = [System.Drawing.Drawing2D.ColorBlend]::new()
        $blend.Positions = [single[]](0.0, 0.55, 1.0)
        $blend.Colors = [System.Drawing.Color[]](
            [System.Drawing.Color]::FromArgb(255, 67, 215, 198),
            [System.Drawing.Color]::FromArgb(255, 90, 97, 240),
            [System.Drawing.Color]::FromArgb(255, 141, 99, 247)
        )
        $gradient.InterpolationColors = $blend
        $graphics.FillRectangle($gradient, $bounds)
        $gradient.Dispose()

        $topGlow = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $topGlow.AddEllipse(-295, -355, 1040, 1040)
        $topGlowBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new($topGlow)
        $topGlowBrush.CenterColor =
            [System.Drawing.Color]::FromArgb(72, 255, 255, 255)
        $topGlowBrush.SurroundColors =
            [System.Drawing.Color[]]([System.Drawing.Color]::FromArgb(0, 255, 255, 255))
        $graphics.FillPath($topGlowBrush, $topGlow)
        $topGlowBrush.Dispose()
        $topGlow.Dispose()

        $shadowBrush = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(18, 8, 17, 38)
        )
        $graphics.FillEllipse($shadowBrush, 620, 650, 700, 700)
        $shadowBrush.Dispose()

        $glassBrush = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(16, 255, 255, 255)
        )
        $graphics.FillEllipse($glassBrush, 256, 236, 430, 430)
        $glassBrush.Dispose()

        $white = [System.Drawing.Color]::White
        $outerPen = [System.Drawing.Pen]::new($white, 77)
        $outerPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $outerPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $graphics.DrawEllipse($outerPen, 256, 236, 430, 430)
        $graphics.DrawLine($outerPen, 617, 597, 737, 737)
        $outerPen.Dispose()

        $highlightPen = [System.Drawing.Pen]::new(
            [System.Drawing.Color]::FromArgb(235, 255, 255, 255),
            46
        )
        $highlightPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $highlightPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $graphics.DrawArc($highlightPen, 353, 333, 236, 236, 189, 130)
        $highlightPen.Dispose()

        $outputDirectory = Split-Path -Parent $OutputPath
        [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
        $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function Resize-Png {
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,
        [Parameter(Mandatory)]
        [string]$OutputPath,
        [Parameter(Mandatory)]
        [int]$Size
    )

    $source = [System.Drawing.Image]::FromFile($SourcePath)
    $target = [System.Drawing.Bitmap]::new(
        $Size,
        $Size,
        [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($target)

    try {
        $graphics.CompositingMode =
            [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality =
            [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode =
            [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode =
            [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode =
            [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
        $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $graphics.DrawImage(
            $source,
            [System.Drawing.Rectangle]::new(0, 0, $Size, $Size),
            0,
            0,
            $source.Width,
            $source.Height,
            [System.Drawing.GraphicsUnit]::Pixel,
            $attributes
        )
        $attributes.Dispose()

        $outputDirectory = Split-Path -Parent $OutputPath
        [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
        $target.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $target.Dispose()
        $source.Dispose()
    }
}

$mobileRoot = Join-Path $ProjectRoot "mobile"
$masterIcon = Join-Path $mobileRoot "assets\branding\degreelens-app-icon-1024.png"

New-DegreeLensMasterIcon -OutputPath $masterIcon

$androidIcons = @{
    "mipmap-mdpi\ic_launcher.png" = 48
    "mipmap-hdpi\ic_launcher.png" = 72
    "mipmap-xhdpi\ic_launcher.png" = 96
    "mipmap-xxhdpi\ic_launcher.png" = 144
    "mipmap-xxxhdpi\ic_launcher.png" = 192
}
$androidRoot = Join-Path $mobileRoot "android\app\src\main\res"

foreach ($entry in $androidIcons.GetEnumerator()) {
    Resize-Png `
        -SourcePath $masterIcon `
        -OutputPath (Join-Path $androidRoot $entry.Key) `
        -Size $entry.Value
}

$iosRoot = Join-Path $mobileRoot "ios\Runner\Assets.xcassets\AppIcon.appiconset"
$iosIcons = @{
    "Icon-App-20x20@1x.png" = 20
    "Icon-App-20x20@2x.png" = 40
    "Icon-App-20x20@3x.png" = 60
    "Icon-App-29x29@1x.png" = 29
    "Icon-App-29x29@2x.png" = 58
    "Icon-App-29x29@3x.png" = 87
    "Icon-App-40x40@1x.png" = 40
    "Icon-App-40x40@2x.png" = 80
    "Icon-App-40x40@3x.png" = 120
    "Icon-App-60x60@2x.png" = 120
    "Icon-App-60x60@3x.png" = 180
    "Icon-App-76x76@1x.png" = 76
    "Icon-App-76x76@2x.png" = 152
    "Icon-App-83.5x83.5@2x.png" = 167
    "Icon-App-1024x1024@1x.png" = 1024
}

foreach ($entry in $iosIcons.GetEnumerator()) {
    Resize-Png `
        -SourcePath $masterIcon `
        -OutputPath (Join-Path $iosRoot $entry.Key) `
        -Size $entry.Value
}

Write-Output "Generated DegreeLens launcher icons from $masterIcon"
