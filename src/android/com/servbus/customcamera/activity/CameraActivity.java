package com.servbus.customcamera.activity;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.hardware.Camera;
import android.media.ThumbnailUtils;
import android.os.Bundle;
import android.os.Environment;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.AnimationSet;
import android.view.animation.AnimationUtils;
import android.view.animation.ScaleAnimation;
import android.view.animation.TranslateAnimation;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import io.cordova.myappb6ea24.R;    //插件安装完成之后，会使用hooks替换成对应的包

import com.servbus.customcamera.utils.BitmapUtils;
import com.servbus.customcamera.utils.CameraUtil;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class CameraActivity extends Activity implements SurfaceHolder.Callback, View.OnClickListener {
    private Camera mCamera;
    private SurfaceView surfaceView;
    private SurfaceHolder mHolder;
    private int mCameraId = 0;
    private Context context;

    //屏幕宽高
    private int screenWidth;
    private int screenHeight;
    //    private LinearLayout home_custom_top_relative;
    private ImageView flash_light;

    //底部高度 主要是计算切换正方形时的动画高度
    private int menuPopviewHeight;
    //闪光灯模式 0:关闭 1: 开启 2: 自动
    private int light_num = 0;

    private boolean isview = false;
    private ImageView camera_close;
    private RelativeLayout homecamera_bottom_relative;
    private ImageView img_camera;
    private ImageView img_picThumbnail;

    boolean mFocusEnd;
    int mDisplayRotate;
    int mViewWidth;
    int mViewHeight;


    public static CallbackContext callbackContext;
    public static CordovaInterface cordova;
    public static String dir;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_camera);
        context = this;
        DisplayMetrics dm = context.getResources().getDisplayMetrics();
        screenWidth = dm.widthPixels;
        screenHeight = dm.heightPixels;

        initView();
    }


    private void initView() {
        surfaceView = (SurfaceView) findViewById(R.id.surfaceView);
        surfaceView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, final MotionEvent event) {

                //if (event.getAction() == MotionEvent.ACTION_UP) {
                focusOnWorkerThread(event, mViewWidth, mViewHeight);
                //}
                return true;
            }
        });


        mHolder = surfaceView.getHolder();
        mHolder.addCallback(this);

        img_camera = (ImageView) findViewById(R.id.img_camera);
        img_camera.setOnClickListener(this);

        img_picThumbnail = (ImageView) findViewById(R.id.img_picThumbnail);
//        img_picThumbnail.setAlpha(0.8f);
        img_picThumbnail.setOnClickListener(this);


        //关闭相机界面按钮
        camera_close = (ImageView) findViewById(R.id.camera_close);
        camera_close.setOnClickListener(this);

        //top 的view
//        home_custom_top_relative = (LinearLayout) findViewById(R.id.home_custom_top_relative);
//        home_custom_top_relative.setAlpha(0.5f);


        //闪光灯
        flash_light = (ImageView) findViewById(R.id.flash_light);
        flash_light.setOnClickListener(this);

//        homecamera_bottom_relative = (RelativeLayout) findViewById(R.id.homecamera_bottom_relative);

        //设置取景框比例为4：3，程序为竖屏显示，所以高大于宽
        LinearLayout bottomLayout = (LinearLayout) findViewById(R.id.bottomLayout);
        ViewGroup.LayoutParams params = surfaceView.getLayoutParams();
        int height = screenHeight - bottomLayout.getLayoutParams().height;
        int width = screenWidth;

        int tmpHeight = (int) (4 * 1.0 / 3 * width);
        if (tmpHeight > height) {
            width = (int) (height / (4 * 1.0 / 3));
        } else {
            height = tmpHeight;
        }
        params.height = height;
        params.width = width;
        surfaceView.setLayoutParams(params);


        mViewWidth = surfaceView.getWidth();
        mViewHeight = surfaceView.getHeight();


    }


    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.img_camera:
//                if (isview) {
                switch (light_num) {
                    case 0:
                        //关闭
                        CameraUtil.getInstance().turnLightOff(mCamera);
                        break;
                    case 1:
                        CameraUtil.getInstance().turnLightOn(mCamera);
                        break;
                    case 2:
                        //自动
                        CameraUtil.getInstance().turnLightAuto(mCamera);
                        break;
                }
                captrue();
//                    isview = false;
//                }
                break;

            //退出相机界面 释放资源
            case R.id.camera_close:
                finish();
                //returnData();
                break;
            case R.id.img_picThumbnail:
                finish();
                break;

            //闪光灯
            case R.id.flash_light:
                if (mCameraId == 1) {
                    //前置
                    return;
                }
                Camera.Parameters parameters = mCamera.getParameters();
                switch (light_num) {
                    case 0:
                        //打开
                        light_num = 1;
                        flash_light.setImageResource(R.drawable.btn_camera_flash_on);
                        parameters.setFlashMode(Camera.Parameters.FLASH_MODE_TORCH);//开启
                        mCamera.setParameters(parameters);
                        break;
                    case 1:
                        //自动
                        light_num = 2;
                        parameters.setFlashMode(Camera.Parameters.FLASH_MODE_AUTO);
                        mCamera.setParameters(parameters);
                        flash_light.setImageResource(R.drawable.btn_camera_flash_auto);
                        break;
                    case 2:
                        //关闭
                        light_num = 0;
                        //关闭
                        parameters.setFlashMode(Camera.Parameters.FLASH_MODE_OFF);
                        mCamera.setParameters(parameters);
                        flash_light.setImageResource(R.drawable.btn_camera_flash_off);
                        break;
                }

                break;

        }
    }


    @Override
    protected void onResume() {
        super.onResume();
        if (mCamera == null) {
            mCamera = getCamera(mCameraId);
            if (mHolder != null) {
                startPreview(mCamera, mHolder);
            }
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        releaseCamera();
    }

    /**
     * 获取Camera实例
     *
     * @return
     */
    private Camera getCamera(int id) {
        Camera camera = null;
        try {
            camera = Camera.open(id);
        } catch (Exception e) {

        }
        return camera;
    }

    /**
     * 预览相机
     */
    private void startPreview(Camera camera, SurfaceHolder holder) {
        try {
            setupCamera(camera);
            camera.setPreviewDisplay(holder);
            //亲测的一个方法 基本覆盖所有手机 将预览矫正
            CameraUtil.getInstance().setCameraDisplayOrientation(this, mCameraId, camera);
//            camera.setDisplayOrientation(90);
            camera.startPreview();
            isview = true;
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    /**
     * 根据指定的图像路径和大小来获取缩略图
     * 此方法有两点好处：
     * 1. 使用较小的内存空间，第一次获取的bitmap实际上为null，只是为了读取宽度和高度，
     * 第二次读取的bitmap是根据比例压缩过的图像，第三次读取的bitmap是所要的缩略图。
     * 2. 缩略图对于原图像来讲没有拉伸，这里使用了2.2版本的新工具ThumbnailUtils，使
     * 用这个工具生成的图像不会被拉伸。
     *
     * @param imagePath 图像的路径
     * @param width     指定输出图像的宽度
     * @param height    指定输出图像的高度
     * @return 生成的缩略图
     */
    private Bitmap getImageThumbnail(String imagePath, int width, int height) {
        Bitmap bitmap = null;
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        // 获取这个图片的宽和高，注意此处的bitmap为null
        bitmap = BitmapFactory.decodeFile(imagePath, options);
        options.inJustDecodeBounds = false; // 设为 false
        // 计算缩放比
        int h = options.outHeight;
        int w = options.outWidth;
        int beWidth = w / width;
        int beHeight = h / height;
        int be = 1;
        if (beWidth < beHeight) {
            be = beWidth;
        } else {
            be = beHeight;
        }
        if (be <= 0) {
            be = 1;
        }
        options.inSampleSize = be;
        // 重新读入图片，读取缩放后的bitmap，注意这次要把options.inJustDecodeBounds 设为 false
        bitmap = BitmapFactory.decodeFile(imagePath, options);
        // 利用ThumbnailUtils来创建缩略图，这里要指定要缩放哪个Bitmap对象
        bitmap = ThumbnailUtils.extractThumbnail(bitmap, width, height,
                ThumbnailUtils.OPTIONS_RECYCLE_INPUT);
        return bitmap;
    }

    /**
     * 获取圆形图片方法
     *
     * @param bitmap
     * @return Bitmap
     * @author caizhiming
     */
    private Bitmap getCircleBitmap(Bitmap bitmap) {
        Bitmap output = Bitmap.createBitmap(bitmap.getWidth(),
                bitmap.getHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(output);
        Paint paint = new Paint();

        final int color = 0xff424242;

        final Rect rect = new Rect(0, 0, bitmap.getWidth(), bitmap.getHeight());
        paint.setAntiAlias(true);
        canvas.drawARGB(0, 0, 0, 0);
        paint.setColor(color);
        int x = bitmap.getWidth();

        canvas.drawCircle(x / 2, x / 2, x / 2, paint);
        paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_IN));
        canvas.drawBitmap(bitmap, rect, rect, paint);
        return output;


    }

    private void captrue() {
        mCamera.takePicture(null, null, new Camera.PictureCallback() {
            @Override
            public void onPictureTaken(final byte[] data, Camera camera) {
                isview = false;


                cordova.getActivity().runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        AlphaAnimation alphaAnimation = new AlphaAnimation(1, 0);
                        alphaAnimation.setDuration(100);
                        surfaceView.startAnimation(alphaAnimation);

                        //将data 转换为位图 或者你也可以直接保存为文件使用 FileOutputStream
                        //这里我相信大部分都有其他用处把 比如加个水印 后续再讲解
                        Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
                        Bitmap saveBitmap = CameraUtil.getInstance().setTakePicktrueOrientation(mCameraId, bitmap);


                        String img_path_tmp = cordova.getActivity().getExternalFilesDir("") + "/" + dir + "/" + System.currentTimeMillis();
                        String img_path = img_path_tmp + ".jpg";
                        String img_path_t = img_path_tmp + "_t.jpg";
                        BitmapUtils.saveJPGE_After(context, saveBitmap, img_path, 100);


                        ScaleAnimation scaleAnimation = new ScaleAnimation(0, 1, 0, 1, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
                        scaleAnimation.setDuration(400);
                        img_picThumbnail.startAnimation(scaleAnimation);

                        Bitmap bitmap_t = getImageThumbnail(img_path, 200, 200);
                        BitmapUtils.saveJPGE_After(context, bitmap_t, img_path_t, 100);
                        returnData(img_path);
                        Bitmap bitmap_c = getCircleBitmap(bitmap_t);

                        img_picThumbnail.setImageBitmap(bitmap_c);
                        if (!bitmap.isRecycled()) {
                            bitmap.recycle();
                        }

                        if (!saveBitmap.isRecycled()) {
                            saveBitmap.recycle();
                        }
                    }
                });


                mCamera.startPreview();
//                startPreview(mCamera, mHolder);


                //这里打印宽高 就能看到 CameraUtil.getInstance().getPropPictureSize(parameters.getSupportedPictureSizes(), 200);
                // 这设置的最小宽度影响返回图片的大小 所以这里一般这是1000左右把我觉得
//                Log.d("bitmapWidth==", bitmap.getWidth() + "");
//                Log.d("bitmapHeight==", bitmap.getHeight() + "");
            }
        });
    }

    /**
     * 设置
     */
    private void setupCamera(Camera camera) {
        Camera.Parameters parameters = camera.getParameters();
        //取4：3的尺寸
        Camera.Size optionSize = CameraUtil.getInstance().getOptimalPreviewSize(parameters.getSupportedPreviewSizes());
        parameters.setPreviewSize(optionSize.width, optionSize.height);
        Camera.Size pictrueSize = CameraUtil.getInstance().getOptimalPreviewSize(parameters.getSupportedPictureSizes());
        parameters.setPictureSize(pictrueSize.width, pictrueSize.height);
        camera.setParameters(parameters);

    }

    /**
     * 释放相机资源
     */
    private void releaseCamera() {
        if (mCamera != null) {
            mCamera.setPreviewCallback(null);
            mCamera.stopPreview();
            mCamera.release();
            mCamera = null;
        }
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        startPreview(mCamera, holder);
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        mCamera.stopPreview();
        startPreview(mCamera, holder);
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        releaseCamera();
    }


    /**
     * 触摸对焦
     **/


    void focusOnWorkerThread(final MotionEvent event, final int viewWidth, final int viewHeight) {
        if (null == mCamera) {
            //Log.e(TAG, "camera not initialized");
            return;
        }

//        if (false == mFocusEnd) {
//            //Log.d(TAG, "autofocusing...");
//            return;
//        }
//        mFocusEnd=false;

        //// TODO: 2017/3/30 api level below 14, can't use foucs area


        Rect focusRect = calculateTapArea(event.getRawX(), event.getRawY(), mDisplayRotate, viewWidth, viewHeight, 1f);
        Rect meteringRect = calculateTapArea(event.getRawX(), event.getRawY(), mDisplayRotate, viewWidth, viewHeight, 1.5f);

        Camera.Parameters parameters = mCamera.getParameters();
        List<String> modes = parameters.getSupportedFocusModes();
        if (!modes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
            //Log.e(TAG, "camera don't support auto focus");
            return;
        }
        parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);

        if (parameters.getMaxNumFocusAreas() > 0) {
            List<Camera.Area> focusAreas = new ArrayList<Camera.Area>();
            focusAreas.add(new Camera.Area(focusRect, 1000));
            parameters.setFocusAreas(focusAreas);
        }

        if (parameters.getMaxNumMeteringAreas() > 0) {
            List<Camera.Area> meteringAreas = new ArrayList<Camera.Area>();
            meteringAreas.add(new Camera.Area(meteringRect, 1000));

            parameters.setMeteringAreas(meteringAreas);
        }


        //对焦时是否许需要打开闪光灯
        //parameters.setFlashMode(Camera.Parameters.FLASH_MODE_TORCH);


        try {
            mCamera.setParameters(parameters);
            mCamera.autoFocus(mAutoFocusCallback);
            //Log.i(TAG, "start autoFocus");
        } catch (Exception e) {
            //Log.e(TAG, "autofocus failed, " + e.getMessage());
            mFocusEnd = true;
        }
    }

    Camera.AutoFocusCallback mAutoFocusCallback = new Camera.AutoFocusCallback() {
        @Override
        public void onAutoFocus(boolean success, Camera camera) {
            mFocusEnd = true;
        }
    };

    /**
     * Convert touch position x:y to {@link Camera.Area} position -1000:-1000 to 1000:1000.
     */
    @SuppressWarnings("SuspiciousNameCombination")
    Rect calculateTapArea(float x, float y, int rotation, int viewWidth, int viewHeight, float coefficient) {
        float focusAreaSize = 300;
        int areaSize = Float.valueOf(focusAreaSize * coefficient).intValue();

        int tempX = (int) (x / viewWidth * 2000 - 1000);
        int tempY = (int) (y / viewHeight * 2000 - 1000);

        int centerX = 0, centerY = 0;
        if (90 == rotation) {
            centerX = tempY;
            centerY = (2000 - (tempX + 1000) - 1000);
        } else if (270 == rotation) {
            centerX = (2000 - (tempY + 1000)) - 1000;
            centerY = tempX;
        }

        int left = clamp(centerX - areaSize / 2, -1000, 1000);
        int right = clamp(left + areaSize, -1000, 1000);
        int top = clamp(centerY - areaSize / 2, -1000, 1000);
        int bottom = clamp(top + areaSize, -1000, 1000);

        return new Rect(left, top, right, bottom);
    }

    int clamp(int x, int min, int max) {
        if (x > max) return max;
        if (x < min) return min;
        return x;
    }

    private void returnData(String path) {
        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, path);
        //true：回调继续保持，即当前返回后后面还会有返回 false:回调结束，即当这个返回后不会再有返回
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
    }
}
