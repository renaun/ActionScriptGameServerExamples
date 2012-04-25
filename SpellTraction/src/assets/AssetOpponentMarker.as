package assets
{
import flash.display.BitmapData;

[Embed(source="/assets/opponent_marker.png")]
public final class AssetOpponentMarker extends BitmapData
{
	public function AssetOpponentMarker()
	{
		super(8, 8, true);
	}
}
}