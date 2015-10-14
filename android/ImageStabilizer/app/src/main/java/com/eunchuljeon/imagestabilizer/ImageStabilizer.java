package com.eunchuljeon.imagestabilizer;

import android.graphics.Bitmap;
import android.widget.ImageView;

import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.imgproc.Imgproc;

import java.util.ArrayList;

/**
 * Created by eunchuljeon on 15. 10. 14..
 */
public class ImageStabilizer {

    public ArrayList<Bitmap> featureExtraction(ArrayList<Bitmap> originals){
        ArrayList<Bitmap> results = new ArrayList<Bitmap>();

        for( int i =0; i < originals.size(); i++){
            Bitmap bmp = originals.get(i);
            Mat tmp = new Mat(bmp.getWidth(), bmp.getHeight(), CvType.CV_8UC4);
            Utils.bitmapToMat(bmp, tmp);
            Imgproc.cvtColor(tmp, tmp, Imgproc.COLOR_BGRA2GRAY);

            Bitmap bmp2 = Bitmap.createBitmap(tmp.cols(), tmp.rows(), Bitmap.Config.ARGB_8888);
            Utils.matToBitmap(tmp, bmp2);
            results.add(bmp2);
        }

        return results;
    }
}
