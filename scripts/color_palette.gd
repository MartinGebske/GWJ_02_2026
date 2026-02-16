extends Node
class_name BarColorPalette

enum PaletteType {
	NEON,
	RETRO,
	PASTELL,
	YELLOW,
	BLUE,
	VIOLETT,
	MONOCHROMATIC,
	RAINBOW
}

@export var palette_type: PaletteType = PaletteType.NEON

func get_color(bar_index: int, total_bars: int) -> Color:
	match palette_type:
		PaletteType.NEON:
			var colors = [
				Color("#00FFFF"), Color("#FF00FF"), Color("#FFFF00"),
				Color("#00FF00"), Color("#FF8000"), Color("#FF0000")
				]
			return colors[bar_index % colors.size()]
		PaletteType.RETRO:
			var colors = [
				Color("#FF0000"), Color("#00FF00"), Color("#0000FF"),
				Color("#FFFF00"), Color("#FF00FF")
			]
			return colors[bar_index % colors.size()]
		PaletteType.PASTELL:
			var colors = [
				Color("#FFD1DC"), Color("#DDA0DD"), Color("#98FB98"),
				Color("#87CEFA"), Color("#F0E68C")
			]
			return colors[bar_index % colors.size()]
		PaletteType.YELLOW:
			var colors = [
				Color("#FFFF99"), Color("#FFFF66"), Color("#FFFF00"),
				Color("#FFCC00"), Color("#FF9900"), Color("#CC9900")
			]
			return colors[bar_index % colors.size()]
		PaletteType.BLUE:
			var colors = [
				Color("#00FFFF"), Color("#00BFFF"), Color("#1E90FF"),
				Color("#0000FF"), Color("#0000CC"), Color("#00008B")
				]
			return colors[bar_index % colors.size()]
		PaletteType.VIOLETT:
			var colors = [
				Color("#B388FF"), Color("#9966FF"), Color("#8040C0"),
				Color("#663399"), Color("#4D0099"), Color("#330066")
				]
			return colors[bar_index % colors.size()]
		PaletteType.MONOCHROMATIC:
			var grayscale = 0.3 + (bar_index / float(total_bars) * 0.7)
			return Color(grayscale, grayscale, grayscale)
		PaletteType.RAINBOW:
			var hue = float(bar_index) / float(total_bars)
			return Color.from_hsv(hue, 0.8, 1.0)
		_:
			return Color.WHITE
