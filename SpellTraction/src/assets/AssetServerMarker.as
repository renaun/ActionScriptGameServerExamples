package assets
{
import flash.display.BitmapData;

[Embed(source="/assets/server_marker.png")]
public final class AssetServerMarker extends BitmapData
{
	public function AssetServerMarker()
	{
		super(32, 32, true);
	}
}
}