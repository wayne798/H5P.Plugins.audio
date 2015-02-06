//
//  PGMedia.m
//  Pandora
//
//  Created by lxz on 13-3-6.
//
//

#import "PGMedia.h"
#import "PTPathUtil.h"
#import "PDRCoreWindowManager.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"
#include <objc/message.h>
#import "PDRCommonString.h"
#import "VoiceConverter.h"

typedef enum
{
	EDHA_SUPPORT_WAV,
	EDHA_SUPPORT_MP3,
	EDHA_SUPPORT_AAC,
	EDHA_SUPPORT_AMR
}ESUPPORTFORMAT;

static NSString* const kPGAudioRecorderKey = @"Recorder";

static NSString* const kPGAudioRecorderParams_aac = @"aac";
static NSString* const kPGAudioRecorderParams_amr = @"amr";
static NSString* const kPGAudioRecorderParams_wav = @"wav";
static NSString* const kPGAudioRecorderKey_cbid   = @"a";
static NSString* const kPGAudioRecorderKey_outFile   = @"b";
static NSString* const kPGAudioRecorderKey_recordFile   = @"c";
static NSString* const kPGAudioRecorderKey_isamr   = @"d";

@implementation PGAudio

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (BOOL)RecorderExecMethod:(PGMethod*)pMethod
{
    BOOL retVal = NO;
    NSString* methodName = [pMethod.arguments objectAtIndex:0];
    NSString* methodNameWithArgs = [NSString stringWithFormat:@"Recorder_%@:", methodName];
    SEL normalSelector = NSSelectorFromString(methodNameWithArgs);
    if ([self respondsToSelector:normalSelector]) {
        ((BOOL (*)(id, SEL, id))objc_msgSend)(self, normalSelector, [pMethod.arguments objectAtIndex:1]);
        retVal = YES;
    }
    return retVal;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (BOOL)AudioExecMethod:(PGMethod*)pMethod
{
    BOOL retVal = NO;
    NSString* methodName = [pMethod.arguments objectAtIndex:0];
    NSString* methodNameWithArgs = [NSString stringWithFormat:@"Player_%@:", methodName];
    SEL normalSelector = NSSelectorFromString(methodNameWithArgs);
    if ([self respondsToSelector:normalSelector]) {
        ((BOOL (*)(id, SEL, id))objc_msgSend)(self, normalSelector, [pMethod.arguments objectAtIndex:1]);
        retVal = YES;
    }
    return retVal;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (NSData*)AudioSyncExecMethod:(PGMethod*)pMethod
{
    NSString* methodName = [pMethod.arguments objectAtIndex:0];
    NSString* methodNameWithArgs = [NSString stringWithFormat:@"Player_Sync_%@:", methodName];
    SEL normalSelector = NSSelectorFromString(methodNameWithArgs);
    if ([self respondsToSelector:normalSelector]) {      
        return ((id (*)(id, SEL, id))objc_msgSend)(self, normalSelector, [pMethod.arguments objectAtIndex:1]);
    }
    return nil;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Recorder_record:(NSArray*)pMethod
{
    BOOL bSucess = false;
    
    NSString* pRecorderFileName = nil;
    NSString* pOutFileName = nil;
    
    NSString* pOptionFileName = @"_doc/";
    CGFloat nSamplateRate = 8000.0f;
    ESUPPORTFORMAT eRecFormat = EDHA_SUPPORT_WAV;
    NSString* fileType = kPGAudioRecorderParams_wav;
    
    NSString* pRecorderUdid = [pMethod objectAtIndex:0];
    NSString* pCallBackID = [pMethod objectAtIndex:1];
    NSDictionary* pRecOption = [pMethod objectAtIndex:2];
    
    if (m_pRecorderDic == nil) {
        m_pRecorderDic = [[NSMutableDictionary alloc] init];
    }
    
    if ( pRecOption && [pRecOption isKindOfClass:[NSDictionary class]]) {
        // 获取文件名
        NSString *fileNameValue = [pRecOption objectForKey:@"filename"];
        if ( [fileNameValue isKindOfClass:[NSString class]] ) {
            pOptionFileName = fileNameValue;
        }
        
        // 获取采样率
        NSNumber *sampValue = [pRecOption objectForKey:@"samplerate"];
        if ( [sampValue isKindOfClass:[NSString class]]
            || [sampValue isKindOfClass:[NSNumber class]]) {
            nSamplateRate = [sampValue floatValue];
        }
        
        NSString *fileTypeJSP = [pRecOption objectForKey:@"format"];
        if ( [fileTypeJSP isKindOfClass:[NSString class]] ) {
            if ( NSOrderedSame == [kPGAudioRecorderParams_aac caseInsensitiveCompare:fileTypeJSP] ) {
                eRecFormat = EDHA_SUPPORT_AAC;
                fileType = kPGAudioRecorderParams_aac;
            } else if (  NSOrderedSame == [kPGAudioRecorderParams_amr caseInsensitiveCompare:fileTypeJSP] ) {
                eRecFormat = EDHA_SUPPORT_AMR;
                fileType = kPGAudioRecorderParams_amr;
            }
        }
    }
    
    pOutFileName = [PTPathUtil absolutePath:pOptionFileName
                                   suggestedPath:nil
                               suggestedFilename:nil
                                          prefix:@"Recorder_"
                                          suffix:fileType];
    if ( [PTPathUtil allowsWritePath:pOutFileName withContext:self.appContext] ) {
        NSMutableDictionary* FormatDic = [NSMutableDictionary dictionary];
        
        if ( EDHA_SUPPORT_AMR == eRecFormat ) {
            pRecorderFileName = [pOutFileName stringByAppendingPathExtension:@"wav"];
        } else {
            pRecorderFileName = pOutFileName;
        }
        
        switch (eRecFormat){
            case EDHA_SUPPORT_AAC: {
                [FormatDic setObject:[NSNumber numberWithInt: kAudioFormatMPEG4AAC] forKey: AVFormatIDKey];
                //[FormatDic setObject:[NSNumber numberWithInt:44100] forKey:AVEncoderBitRateKey];
                [FormatDic setObject:[NSNumber numberWithInt: AVAudioQualityHigh] forKey: AVEncoderAudioQualityKey];
            }
                break;
            case EDHA_SUPPORT_WAV:
            case EDHA_SUPPORT_AMR: {
                [FormatDic setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
                [FormatDic setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
                [FormatDic setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
                [FormatDic setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
                
            }
                break;
            default:
                break;
        }
        
        [FormatDic setObject:[NSNumber numberWithFloat:nSamplateRate] forKey: AVSampleRateKey];
        [FormatDic setObject:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        NSURL* pURL = [NSURL fileURLWithPath:pRecorderFileName];
        NSError *error = nil;
        AVAudioRecorder* pAURecorder = [[AVAudioRecorder alloc] initWithURL:pURL settings:FormatDic error:&error];
        if ( pAURecorder ) {
            [pAURecorder prepareToRecord];
            if ( [pAURecorder record] ) {
                bSucess = YES;
                [FormatDic removeAllObjects];
                [FormatDic setObject:pAURecorder forKey:kPGAudioRecorderKey];
                [FormatDic setObject:pCallBackID forKey:kPGAudioRecorderKey_cbid];
                [FormatDic setObject:pRecorderFileName forKey:kPGAudioRecorderKey_recordFile];
                [FormatDic setObject:pOutFileName forKey:kPGAudioRecorderKey_outFile];
                if ( eRecFormat == EDHA_SUPPORT_AMR  ) {
                   // [VoiceConverter changeStu];
                    [FormatDic setObject:[NSNumber numberWithBool:true] forKey:kPGAudioRecorderKey_isamr];
//                    //启动计时器
//                    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
//                                                                                            selector:@selector(wavToAmrBtnPressed:)
//                                                                                              object:[NSArray arrayWithObjects:pRecorderFileName,pOutFileName, nil]];
//                    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//                    [queue addOperation:operation];
                } else {
                    [FormatDic setObject:[NSNumber numberWithBool:false] forKey:kPGAudioRecorderKey_isamr];
                }
                [m_pRecorderDic setObject:FormatDic forKey:pRecorderUdid];
                [pAURecorder release];
                return;
            }
            [pAURecorder release];
        }
        [FormatDic removeAllObjects];
    }

    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:1 withMessage:@"参数错误"];
    [self toCallback:pCallBackID withReslut:[result toJSONString]];
}
//
//- (void)wavToAmrBtnPressed:(NSArray*)originWav{
//    if ([originWav count] == 2){
//        //转格式
//       // [VoiceConverter wavToAmr:[originWav objectAtIndex:0] amrSavePath:[originWav objectAtIndex:1]];
//    }
//}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Recorder_pause:(NSArray*)pMethod
{
    return;
    NSString* pRecorderUUID = [pMethod objectAtIndex:0];
    AVAudioRecorder* pRecorder = [m_pRecorderDic objectForKey:pRecorderUUID];
    if (pRecorder)
    {
        [pRecorder pause];
    }
}
/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Recorder_stop:(NSArray*)pMethod
{
    NSString* pRecorderUUID = [pMethod objectAtIndex:0];
    if (pRecorderUUID == NULL) {
        return;
    }
    NSMutableDictionary* pDic = [m_pRecorderDic objectForKey:pRecorderUUID];
    if ( pDic ) {
        NSString* pCallBackID = [pDic objectForKey:kPGAudioRecorderKey_cbid];
        NSString* pFileName   = [pDic objectForKey:kPGAudioRecorderKey_outFile];
        NSString* pRecodeFileName   = [pDic objectForKey:kPGAudioRecorderKey_recordFile];
        NSNumber* isAmr = [pDic objectForKey:kPGAudioRecorderKey_isamr];
        AVAudioRecorder* pRecorder = [pDic objectForKey:kPGAudioRecorderKey];
        if (pRecorder){
            [pRecorder stop];
        }
        if ( [isAmr boolValue] ) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [VoiceConverter wavToAmr:pRecodeFileName amrSavePath:pFileName];
                [[NSFileManager defaultManager] removeItemAtPath:pRecodeFileName error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString * r =[PTPathUtil relativePath:pFileName withContext:self.appContext];
                    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:r];
                    [self toCallback:pCallBackID withReslut:[result toJSONString]];
                    [m_pRecorderDic removeObjectForKey:pRecorderUUID];
                });
            });
        } else {
            NSString * r =[PTPathUtil relativePath:pFileName withContext:self.appContext];
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:r];
            [self toCallback:pCallBackID withReslut:[result toJSONString]];
            [m_pRecorderDic removeObjectForKey:pRecorderUUID];
        }
    }

    // 录音列表空了就释放
    if ([m_pRecorderDic count] == 0) {
        [m_pRecorderDic release];
        m_pRecorderDic = nil;
    }
}

- (void)closeRecorder {
    NSArray *recorders = [m_pRecorderDic allValues];
    for ( NSDictionary *dict in recorders ) {
        AVAudioRecorder* pRecorder = [dict objectForKey:kPGAudioRecorderKey];
        if ( pRecorder
            && [pRecorder isKindOfClass:[AVAudioRecorder class]]
            && pRecorder.recording ) {
            [pRecorder stop];
        }
    }
    [m_pRecorderDic removeAllObjects];
    [m_pRecorderDic release];
    m_pRecorderDic = nil;
}

#pragma mark -
#pragma mark Player


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    CGFloat* fValue = (CGFloat*)player;
    
    NSString* pCallBackID = [m_pPlayerCallbackID objectForKey:[NSString stringWithFormat:@"%f", *fValue]];
    if ( pCallBackID ) {
        if ( flag ) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:0 ];
            [self toCallback:pCallBackID withReslut:[result toJSONString]];
        } else {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:3 withMessage:@"播放失败" ];
            [self toCallback:pCallBackID withReslut:[result toJSONString]];
        }
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (NSData*)Player_Sync_CreatePlayer:(NSArray*)pMethod
{
    NSData*     pDataRet          = [[NSString stringWithFormat:@"null"] dataUsingEncoding:NSUTF8StringEncoding];
    NSString*   pPlayerUUID       = nil;
    NSString*   pMusicPath        = nil;
    
    if (pMethod && [pMethod count] > 1)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        pMusicPath = [pMethod objectAtIndex:1];
        
        if ( ![pMusicPath isKindOfClass:[NSString class]] ) {
            pMusicPath = nil;
            return pDataRet;
        }
        
        pMusicPath = [PTPathUtil absolutePath:pMusicPath withContext:self.appContext];
        
        if ( ![[NSFileManager defaultManager] fileExistsAtPath:pMusicPath] ) {
            return pDataRet;
        }
        
        // 找到文件的绝对路径之后转化成URl
        NSURL* pFileUrl = [NSURL fileURLWithPath:pMusicPath];
        // 创建Player
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        AVAudioPlayer* pPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:pFileUrl error:nil];
        if ( pPlayer )  {
            pPlayer.delegate = self;
            if (m_pPlayerDic == nil){
                m_pPlayerDic = [[NSMutableDictionary alloc] init];
            }
            [m_pPlayerDic setObject:pPlayer forKey: pPlayerUUID];
            [pPlayer release];
        }
    }

    return pDataRet;
}

- (void)closePlayer {
    NSArray *allPlayer = [m_pPlayerDic allValues];
    for ( AVAudioPlayer *player in allPlayer ) {
        if ( [player isKindOfClass:[AVAudioPlayer class]]
            && player.playing ) {
            player.delegate = nil;
            [player stop];
        }
    }
    [m_pPlayerDic removeAllObjects];
    [m_pPlayerDic release];
    m_pPlayerDic = nil;
    [m_pPlayerCallbackID removeAllObjects];
    [m_pPlayerCallbackID release];
    m_pPlayerCallbackID = nil;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Player_play:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    NSString* pCallBackID = nil;
    if ( pMethod && [pMethod count] > 1)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        pCallBackID = [pMethod objectAtIndex:1];
        if (pPlayerUUID)  {
            AVAudioPlayer* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayer) {
                if (![pPlayer play])
                {
                    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:1 withMessage:@"播放出现错误"];
                    [self toCallback:pCallBackID withReslut:[result toJSONString]];
                } else {
                    if (nil == m_pPlayerCallbackID) {
                        m_pPlayerCallbackID = [[NSMutableDictionary alloc] init];
                    }
                    CGFloat* fValue = (CGFloat*)pPlayer;
                    [m_pPlayerCallbackID setObject:pCallBackID forKey:[NSString stringWithFormat:@"%f", *fValue]];
                }
            } else {
                PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:2 withMessage:@"文件未找到"];
                [self toCallback:pCallBackID withReslut:[result toJSONString]];
            }
        }
    }
}


/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Player_pause:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0) {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            AVAudioPlayer* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayer){
                [pPlayer pause];
            }
        }
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Player_resume:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0) {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            AVAudioPlayer* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];

            if (pPlayer) {
                [pPlayer play];
            }
        }
    }
}


/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Player_stop:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            AVAudioPlayer* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayer) {
                [pPlayer stop];
            }
        }
    }
    
    [m_pPlayerDic removeObjectForKey:pPlayerUUID];
}


/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Player_seekTo:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    NSInteger pPlayTime   = 0;
    if ( pMethod && [pMethod count] > 1)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        NSNumber *seekValue = [pMethod objectAtIndex:1];
        if ( [seekValue isKindOfClass:[NSNumber class]]
            || [seekValue isKindOfClass:[NSString class]]) {
            pPlayTime = [seekValue integerValue];
            if (pPlayerUUID){
                AVAudioPlayer* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
                if (pPlayer) {
                    pPlayer.currentTime = pPlayTime;
                }
            }
        }
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Player_setRoute:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    NSInteger nPlayOutput   = 0;
    if ( pMethod && [pMethod count] > 1)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        NSNumber *seekValue = [pMethod objectAtIndex:1];
        if ( [seekValue isKindOfClass:[NSNumber class]]
            || [seekValue isKindOfClass:[NSString class]]) {
            nPlayOutput = [seekValue integerValue];
            if ( pPlayerUUID ){
                AVAudioPlayer* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
                if (pPlayer) {
                    UInt32 audioRouteOverride = PGAudioOutputEarpiece == nPlayOutput ? kAudioSessionOverrideAudioRoute_None:kAudioSessionOverrideAudioRoute_Speaker;
                    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
                }
            }
        }
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (NSData*)Player_Sync_getDuration:(NSArray*)pMethod
{
    NSData*   pDataRet = [self resultWithInt:-1];
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            AVAudioPlayer* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            if ( pPlayer ) {
                pDataRet = [self resultWithDouble:pPlayer.duration];
            }
        }
    }
    return pDataRet;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (NSData*)Player_Sync_getPosition:(NSArray*)pMethod
{
    NSData*   pDataRet = [self resultWithDouble:0.0f];
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            AVAudioPlayer* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayer) {
                pDataRet = [self resultWithDouble:pPlayer.currentTime];
            }
        }
    }
    return pDataRet;
}

- (void)dealloc {
    [self closeRecorder];
    [self closePlayer];
    [super dealloc];
}

@end
