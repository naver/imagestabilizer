package com.eunchuljeon.imagestabilizer;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.View;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ImageView;

import org.opencv.android.BaseLoaderCallback;
import org.opencv.android.CameraBridgeViewBase;
import org.opencv.android.LoaderCallbackInterface;
import org.opencv.android.OpenCVLoader;

import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.imgproc.Imgproc;


public class MainActivity extends AppCompatActivity {
    public enum DataSet{
        DATA_SET_1,
        DATA_SET_2,
        DATA_SET_3,
        DATA_SET_4
    }

    private TimerTask mTask;
    private Timer mTimer;
    private TimerTask jobTask;
    private Timer jobTimer;

    private int imageIndex = 0;
    private int[] originalImageIndexes;
    private ArrayList<Bitmap> originalImages;
    private ArrayList<Bitmap> resultImages;
    private ArrayList<Mat> resultMats;
    private DataSet currentDataSet = DataSet.DATA_SET_4;
    private ImageStabilizer stabilizer = new ImageStabilizer();
    private boolean hasResultImage = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        loadCurrentDataSet();
        originalImages = getOriginialImages();

        mTask = new TimerTask() {
            @Override
            public void run() {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        ImageView imageView = (ImageView) findViewById(R.id.imageView1);
                        imageView.setImageBitmap(originalImages.get(imageIndex));

                        if(hasResultImage && imageIndex < resultImages.size()){
                            ImageView resultImageView = (ImageView) findViewById(R.id.imageView2);
                            resultImageView.setImageBitmap(resultImages.get(imageIndex));
                        }

                        imageIndex++;

                        if (imageIndex > originalImageIndexes.length-1) {
                            imageIndex = 0;
                        }
                    }
                });
            }
        };

        mTimer = new Timer();
        mTimer.schedule(mTask, 200, 200);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    protected void onDestroy() {
        mTimer.cancel();
        jobTimer.cancel();
        super.onDestroy();
    }

    public void changeImageSetClicked(View view){
        System.out.println("[Change Image Set Clicked]");

        switch(currentDataSet){
            case DATA_SET_1:
                currentDataSet = DataSet.DATA_SET_2;
                break;
            case DATA_SET_2:
                currentDataSet = DataSet.DATA_SET_3;
                break;
            case DATA_SET_3:
                currentDataSet = DataSet.DATA_SET_4;
                break;
            case DATA_SET_4:
                currentDataSet = DataSet.DATA_SET_1;
                break;
        }

        loadCurrentDataSet();
        originalImages = getOriginialImages();
    }
    public void featureExtractionClicked(View view){
        System.out.println("[Feature Extraction Clicked]");
        hasResultImage = false;
        resultImages = stabilizer.featureExtraction(originalImages);
        hasResultImage = true;
    }
    public void featureMatchingClicked(View view){
        System.out.println("[Feature Matching Clicked]");

        jobTask = new TimerTask() {
            @Override
            public void run() {

                hasResultImage = false;
                resultMats = stabilizer.matchedFeatureWithImageList(originalImages);

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {

                        if(resultImages == null){
                            resultImages = new ArrayList<Bitmap>();
                        }else{
                            resultImages.clear();
                        }

                        for(int i = 0; i < resultMats.size(); i++){
                            Mat tmp = resultMats.get(i);
                            Bitmap bmp2 = Bitmap.createBitmap(tmp.cols(), tmp.rows(), Bitmap.Config.ARGB_8888);
                            Utils.matToBitmap(tmp, bmp2);
                            resultImages.add(bmp2);
                        }

                        hasResultImage = true;
                    }
                });
            }
        };

        jobTimer = new Timer();
        jobTimer.schedule(jobTask, 0);

    }
    public void stabilizationClicked(View view){
        jobTask = new TimerTask() {
            @Override
            public void run() {
                hasResultImage = false;
                resultMats = stabilizer.stabilizeWithImageList(originalImages);

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {

                        if(resultImages == null){
                            resultImages = new ArrayList<Bitmap>();
                        }else{
                            resultImages.clear();
                        }

                        for(int i = 0; i < resultMats.size(); i++){
                            Mat tmp = resultMats.get(i);
                            Bitmap bmp2 = Bitmap.createBitmap(tmp.cols(), tmp.rows(), Bitmap.Config.ARGB_8888);
                            Utils.matToBitmap(tmp, bmp2);
                            resultImages.add(bmp2);
                        }

                        hasResultImage = true;
                    }
                });
            }
        };

        jobTimer = new Timer();
        jobTimer.schedule(jobTask, 0);
    }

    private ArrayList<Bitmap> getOriginialImages(){
        ArrayList<Bitmap> originalImages = new ArrayList<Bitmap>();
        int MAX_IMAGE_SIZE = 720;

        for(int i = 0; i < originalImageIndexes.length; i++){
            Bitmap image = BitmapFactory.decodeResource(getResources(), originalImageIndexes[i]);

            if(image.getWidth()>MAX_IMAGE_SIZE){
                int width = MAX_IMAGE_SIZE;
                int height = (int)(image.getHeight()*((double)MAX_IMAGE_SIZE/(double)image.getHeight()));

                Bitmap resized = Bitmap.createScaledBitmap(image, width, height,true );
                originalImages.add(resized);
            }else if (image.getHeight()>MAX_IMAGE_SIZE){
                int width = (int)(image.getWidth()*((double)MAX_IMAGE_SIZE/image.getWidth()));
                int height = MAX_IMAGE_SIZE;

                Bitmap resized = Bitmap.createScaledBitmap(image, width, height,true );
                originalImages.add(resized);
            }else{
                originalImages.add(image);
            }
        }

        return originalImages;
    }

    @Override
    public void onResume(){
        super.onResume();
        OpenCVLoader.initAsync(OpenCVLoader.OPENCV_VERSION_3_0_0, this, mLoaderCallback);
    }

    private BaseLoaderCallback mLoaderCallback = new BaseLoaderCallback(this) {
        @Override
        public void onManagerConnected(int status) {
            switch (status) {
                case LoaderCallbackInterface.SUCCESS:
                {
                    Log.i("[OPENCV]", "OpenCV loaded successfully");
                } break;
                default:
                {
                    super.onManagerConnected(status);
                } break;
            }
        }
    };

    private void loadCurrentDataSet(){
        switch (currentDataSet){
            case DATA_SET_1:
                originalImageIndexes = new int[]{R.drawable.data_1_1, R.drawable.data_1_2,R.drawable.data_1_3,R.drawable.data_1_4,R.drawable.data_1_5,R.drawable.data_1_6};
                break;
            case DATA_SET_2:
                originalImageIndexes = new int[]{R.drawable.data_2_1, R.drawable.data_2_2,R.drawable.data_2_3,R.drawable.data_2_4,R.drawable.data_2_5,R.drawable.data_2_6};
                break;
            case DATA_SET_3:
                originalImageIndexes = new int[]{R.drawable.data_3_1, R.drawable.data_3_2,R.drawable.data_3_3,R.drawable.data_3_4,R.drawable.data_3_5};
                break;
            case DATA_SET_4:
                originalImageIndexes = new int[]{R.drawable.data_4_1, R.drawable.data_4_2,R.drawable.data_4_3,R.drawable.data_4_4};
                break;
            default:
                break;
        }

        imageIndex = 0;
        hasResultImage = false;
    }
}
