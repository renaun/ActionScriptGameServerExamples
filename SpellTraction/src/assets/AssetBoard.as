package assets
{
import flash.display.BitmapData;

[Embed(source="/assets/board.png")]
public final class AssetBoard extends BitmapData
{
	public function AssetBoard()
	{
		super(640, 480, false);
	}
}
}