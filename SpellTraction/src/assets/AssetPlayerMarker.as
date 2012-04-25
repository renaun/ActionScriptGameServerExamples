package assets
{
import flash.display.BitmapData;

[Embed(source="/assets/player_marker.png")]
public final class AssetPlayerMarker extends BitmapData
{
	public function AssetPlayerMarker()
	{
		super(32, 32, true);
	}
}
}