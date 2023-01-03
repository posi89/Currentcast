import Cocoa
import SDWebImage
import SwiftSoup
import AVFoundation
import CircularProgressMac
var episodeSelectedIndex: Int!
var playingIndex: Int!
var player: AVPlayer! = nil
var pausedTimes = [CMTime?](repeating: nil, count: episodes.count)
var pausedTimesDictionary: Dictionary = [Int: [CMTime?]]() 
var playerSeconds: Float!
var playerDuration: Float!
var currentSelectedPodcastIndex: Int!
var playCount: Int? = nil
var pausedCount: Int? = nil
var episodesCheck: Int? = nil
var test: Float64? = nil
var sliderStop: Int? = nil
class EpisodesCellView: NSCollectionViewItem {
    @IBOutlet weak var pauseButton: NSButton!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var infoButton: NSButton!
    @IBOutlet weak var episodeDescriptionField: NSTextField!
    @IBOutlet weak var episodesPubDateField: NSTextField!
    @IBOutlet weak var episodeTitleField: NSTextField!
    let networkIndicator = NSProgressIndicator() 
    var pausedTime: CMTime? = nil
    var duration: String!
    let popoverView = NSPopover() 
    let CircularProgress = CircularProgress(size: 30)
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = CGColor.init(gray: 0.9, alpha: 0.2)
        self.view.layer?.cornerRadius = 8
        self.view.layer?.borderColor = NSColor.white.cgColor
        self.view.layer?.borderWidth = 0.0
        infoButton.alphaValue = 0
        infoButton.isEnabled = false
        playButton.alphaValue = 0
        playButton.isEnabled = false
        pauseButton.alphaValue = 0
        pauseButton.isEnabled = false
        episodePubDateField.textColor = .lightGray
        
        let labelXPostion:CGFloat = 325
        let labelYPostion:CGFloat = view.bounds.midY + 13
        let labelWidth:CGFloat = 30
        let labelHeight:CGFloat = 30
        circularProgress.isIndeterminate = true
        circularProgress.frame = CGRect(x: labelXPostion, y: labelYPostion, width: labelWidth, height: labelHeight)
        //        circularProgress.color = NSColor.init(red: 0.39, green: 0.82, blue: 1.0, alpha: 0.9)
        circularProgress.color = .white
        NotificationCenter.default.addObserver(self, selector: #selector(playTestFunction), name: NSNotification.Name(rawValue: "playButton"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseTestFunction), name: NSNotification.Name(rawValue: "pauseButton"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(seekToPosition), name: NSNotification.Name(rawValue: "sliderChanged"), object: nil)
        if UserDefaults.standard.object(forKey: "pausedTimesDictionary") != nil{
            
            let decoded  = UserDefaults.standard.object(forKey: "pausedTimesDictionary") as! Data
            pausedTimesDictionary = try!((NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded as Data) as? [Int: [CMTime?]])!)
            //            pausedTimesDictionary = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Int: [CMTime?]]
        }
        Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(episodeCheck), userInfo: nil, repeats: true)
    }    
    
    /// Highlights the selected episode
    func setHighlight(selected: Bool) {
        view.layer?.borderWidth = selected ? 2.0 : 0.0
    }
    
    /// this function is used to play the paused/new podcast episode from the DetailVC play/pause button
    @objc func playTestFunction(){
        if playCount == episodeSelectedIndex{
            playPauseButtonClicked(Any?.self)
            playCount = nil
        }
        if playCount != nil{
            playCount! += 1
        }
        
    }
    
    
    
    /// this function is used to pause the playing podcast episode from the DetailVC play/pause button
    @objc func pauseTestFunction(){
        if pauseCount == episodeSelectedIndex{
            playPauseButtonClicked(Any?.self)
            pauseCount = nil
        }
        if pauseCount != nil{
            pauseCount! += 1
        }
        
    }
    
    /// This function checks whether there are new episodes of the current selected podcast
    @objc func episodeCheck(){
        if episodesCheck == 1{
            if pausedTimesDictionary[podcastSelecetedIndex]?.count ?? -1 < episodes.count{
                pausedTimesDictionary[podcastSelecetedIndex]?.insert(nil, at: 0)
            }
            episodesCheck? += 1
        }
    }
    
    /// Configures the Episode Cells
    func configureEpisodeCell(episodeCell: Episodes){
        
        episodeTitleField.stringValue = episodeCell.title
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM d, yyyy"
        if episodeCell.episodeDuration.contains(":")
        {
            episodePubDateField.stringValue = "\(dateFormatter.string(from: episodeCell.pubDate)) • \(episodeCell.episodeDuration)"
        }else{
            if episodeCell.episodeDuration.count != 0 {
                if Double(episodeCell.episodeDuration)! >= 3600{
                    duration = String(Int(Double(episodeCell.episodeDuration)! / 60) / 60) + ":" + String(format: "%02d", Int(Double(episodeCell.episodeDuration)! / 60) % 60) + ":" +  String(format: "%02d", Int(Double(episodeCell.episodeDuration)!.truncatingRemainder(dividingBy: 60)))
                    episodePubDateField.stringValue = "\(dateFormatter.string(from: episodeCell.pubDate)) • \(duration!)"
                }else{
                    duration = String(Int(Double(episodeCell.episodeDuration)! / 60) % 60) + ":" +  String(format: "%02d", Int(Double(episodeCell.episodeDuration)!.truncatingRemainder(dividingBy: 60)))
                    episodePubDateField.stringValue = "\(dateFormatter.string(from: episodeCell.pubDate)) • \(duration!)"
                }
            }else{
                episodePubDateField.stringValue = "\(dateFormatter.string(from: episodeCell.pubDate))"
            }
        }
        
        do {
            let doc: Document = try SwiftSoup.parse(episodeCell.podcastDescription)
            episodeDescriptionField.stringValue = (try doc.text())
        } catch Exception.Error( _, let message) {
            print(message)
        } catch {
            print("error")
        }
    }
    
    /// Shows the buttons corresponding to a particular episode cell
    func showButton(atIndexPaths: Int!){
        playButton.isEnabled = true
        pauseButton.isEnabled = true
        infoButton.isEnabled = true
        episodeSelectedIndex = atIndexPaths
        if playingIndex == episodeSelectedIndex && currentSelectedPodcastIndex == podcastSelecetedIndex{
            playButton.alphaValue = 0
            showPlayPauseAnimation(check: 0)
            
        }else{
            showPlayPauseAnimation(check: 1)
        }
        
    }
    func showPlayPauseAnimation(check: CGFloat){
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.5
            infoButton.animator().alphaValue = 1.0
            if playButton.alphaValue == 1{
                playButton.animator().alphaValue = 1 - check
                pauseButton.animator().alphaValue = check
            }else{
                playButton.animator().alphaValue = check
                pauseButton.animator().alphaValue = 1 - check
            }
        }, completionHandler:{
        })
    }
    
    /// Hides the buttons corresponding to a particular episode cell
    func hideButton(atIndexPaths: Int!){
        playButton.isEnabled = false
        pauseButton.isEnabled = false
        infoButton.isEnabled = false
        infoButton.alphaValue = 0
        playButton.alphaValue = 0
        pauseButton.alphaValue = 0
    }
    
    func playPlayer(){
        player?.play()
        currentSelectedPodcastIndex = podcastSelecetedIndex
        playingIndex = episodeSelectedIndex
        sendNotifications()
        updateSlider()
        observePlayPause()
    }
    
    func sendNotifications(){
        playPauseCheck = 1
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setBackground"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "playPausePass"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "playPausePassStatus"), object: nil)
    }
    
    func pausePlayer(){
        player?.pause()
        playPauseCheck = 1
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "playPausePass"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "playPausePassStatus"), object: nil)
        
        let duration = player.currentItem!.duration
        
        if playingIndex == nil{
            if player.currentTime().seconds >= duration.seconds{
                pausedTimes.remove(at: episodeSelectedIndex)
                pausedTimes.insert(CMTime.zero, at: episodeSelectedIndex)
            }else{
                pausedTimes.remove(at: episodeSelectedIndex)
                pausedTimes.insert(player?.currentTime(), at: episodeSelectedIndex)
            }
        }else{
            if player.currentTime().seconds >= duration.seconds{
                pausedTimes.remove(at: playingIndex)
                pausedTimes.insert(CMTime.zero, at: playingIndex)
            }else{
                pausedTimes.remove(at: playingIndex)
                pausedTimes.insert(player?.currentTime(), at: playingIndex)
            }
            
        }
        
        if currentSelectedPodcastIndex == podcastSelecetedIndex{
            pausedTimesDictionary[podcastSelecetedIndex] = pausedTimes
        }else{
            pausedTimesDictionary[currentSelectedPodcastIndex] = pausedTimes
        }

//        let encodedData = NSKeyedArchiver.archivedData(withRootObject: pausedTimesDictionary)
//        let userDefaults = UserDefaults.standard
//        userDefaults.set(encodedData, forKey: "pausedTimesDictionary")
        playingIndex = nil
        
    }


    @IBAction func playPauseButtonClicked(_ sender: Any) {
        if playingIndex != nil
        {
            if playingIndex == episodeSelectedIndex && currentSelectedPodcastIndex == podcastSelecetedIndex{
                if playButton.alphaValue == 1{
                    if episodeSelectedIndex != nil{
                        player = AVPlayer(url: URL(string: episodesURL[episodeSelectedIndex])!)
                        if pausedTimesDictionary[podcastSelecetedIndex]?[episodeSelectedIndex] == nil{
                                                        currentSelectedPodcastIndex = podcastSelecetedIndex
                            playPlayer()
                        }else{
                            player?.seek(to: pausedTimesDictionary[podcastSelecetedIndex]![playingIndex]!)
                            playPlayer()
                        }
                    }
                    playButton.alphaValue = 0
                    pauseButton.alphaValue = 1
                }else{
                    pausePlayer()
                    playingIndex = nil
                    playButton.alphaValue = 1
                    pauseButton.alphaValue = 0
                }
            }else{
                pausePlayer()
                playingIndex = nil
                playPauseButtonClicked(Any?.self)
                updateSlider()
                observePlayPause()
            }
        }else{
            if playButton.alphaValue == 1{
                if episodeSelectedIndex != nil{
                    player = AVPlayer(url: URL(string: episodesURL[episodeSelectedIndex])!)
                    if pausedTimesDictionary[podcastSelecetedIndex]?[episodeSelectedIndex] == nil{
                        playPlayer()
                    }else{
                        playingIndex = episodeSelectedIndex
                        player?.seek(to: pausedTimesDictionary[podcastSelecetedIndex]![playingIndex]!)
                        playPlayer()
                    }
                }
                playButton.alphaValue = 0
                pauseButton.alphaValue = 1
            }else if pauseButton.alphaValue == 1{
                pausePlayer()
                playingIndex = nil
                playButton.alphaValue = 1
                pauseButton.alphaValue = 0
            }
        }
    }
    @objc func seekToPosition(){
        if sliderStop == 0{
            let seekTime = CMTimeMakeWithSeconds(test ?? 0, preferredTimescale: 1)
            player?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
            sliderStop = nil
        }else{
            sliderStop = nil
        }
    }
    

    func observePlayPause(){
        circularProgress.isHidden = false
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        view.addSubview(circularProgress)
    }
    

    func updateSlider(){
        let interval = CMTime(value: 1, timescale: 2)
        player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { (progressTime) in
            let seconds = CMTimeGetSeconds(progressTime)
            playerSeconds = Float(seconds)
            
            if let duration = player.currentItem?.duration{
                let durationSeconds = CMTimeGetSeconds(duration)
                playerDuration = Float(durationSeconds)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "moveSlider"), object: nil)
            }
            
        }
    }
    

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            if newStatus != oldStatus {
                DispatchQueue.main.async {[weak self] in
                    
                    if newStatus == .playing  {
                        self?.circularProgress.isHidden = true
                    } else {
                        self?.circularProgress.isHidden = true
                    }
                }
            }
        }
    }
    
    @IBAction func infoButtonClicked(_ sender: Any) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let vc =  storyboard.instantiateController(withIdentifier: "EpisodeInfoVC") as? NSViewController else { return }
        popoverView.contentViewController = vc
        popoverView.behavior = .transient
        popoverView.show(relativeTo: infoButton.bounds, of: infoButton, preferredEdge: .maxX)
    }
    
    //    override func viewWillDisappear() {
    //        let duration = player.currentItem!.duration
    //        if playingIndex == nil{
    //            if player.currentTime().seconds >= duration.seconds{
    //                pausedTimes.remove(at: episodeSelectedIndex)
    //                pausedTimes.insert(CMTime.zero, at: episodeSelectedIndex)
    //            }else{
    //                pausedTimes.remove(at: episodeSelectedIndex)
    //                pausedTimes.insert(player?.currentTime(), at: episodeSelectedIndex)
    //            }
    //        }else{
    //            if player.currentTime().seconds >= duration.seconds{
    //                pausedTimes.remove(at: playingIndex)
    //                pausedTimes.insert(CMTime.zero, at: playingIndex)
    //            }else{
    //                pausedTimes.remove(at: playingIndex)
    //                pausedTimes.insert(player?.currentTime(), at: playingIndex)
    //            }
    //
    //        }
    //
    //        if currentSelectedPodcastIndex == podcastSelecetedIndex{
    //            pausedTimesDictionary[podcastSelecetedIndex] = pausedTimes
    //        }else{
    //            pausedTimesDictionary[currentSelectedPodcastIndex] = pausedTimes
    //        }
    //
    //        let encodedData = NSKeyedArchiver.archivedData(withRootObject: pausedTimesDictionary)
    //        let userDefaults = UserDefaults.standard
    //        userDefaults.set(encodedData, forKey: "pausedTimesDictionary")
    //    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
}
