;;; password-generator.el --- Password generator for humans. Good, Bad, Phonetic passwords included.

;; Copyright (C) 2021

;; Author: Vandrlexay
;; URL: http://github.com/vandrlexay/emacs-password-genarator
;; Package-Version: 20210425.2227
;; Package-Commit: c1da9790d594bc745cdbcc8003153e408aa92a5f
;; Version: 1.20

;;; Commentary:

;;  Generate a password and insert it in-place.  Such functions provided:

;; password-generator-numeric  - generate PIN-code or any other numeric password.
;; password-generator-simple   - simple password for most websites.
;; password-generator-phonetic - easy to remember password.
;; password-generator-strong   - strong password and still suitable for most web sites with strange password requirements to used special chars.
;; password-generator-words   - generate rememberable password from top used 1500 english words.
;; password-generator-custom   - generate custome password from your alphabete.

;; Use C-u <length> password-generator-simple to specify length of generated password.  This works with other functions too.

;; See full docs here: http://github.com/vandrlexay/emacs-password-genarator

;;; Code:

(defgroup password-generator nil "Password generator for Emacs" :group 'applications)

(defcustom password-generator-vocabulary-nouns '("people" "history" "way" "art" "world" "information" "map" "two" "family" "government" "health" "system" "computer" "meat" "year" "thanks" "music" "person" "reading" "method" "data" "food" "understanding" "theory" "law" "bird" "literature" "problem" "software" "control" "knowledge" "power" "ability" "economics" "love" "internet" "television" "science" "library" "nature" "fact" "product" "idea" "temperature" "investment" "area" "society" "activity" "story" "industry" "media" "thing" "oven" "community" "definition" "safety" "quality" "development" "language" "management" "player" "variety" "video" "week" "security" "country" "exam" "movie" "organization" "equipment" "physics" "analysis" "policy" "series" "thought" "basis" "boyfriend" "direction" "strategy" "technology" "army" "camera" "freedom" "paper" "environment" "child" "instance" "month" "truth" "marketing" "university" "writing" "article" "department" "difference" "goal" "news" "audience" "fishing" "growth" "income" "marriage" "user" "combination" "failure" "meaning" "medicine" "philosophy" "teacher" "communication" "night" "chemistry" "disease" "disk" "energy" "nation" "road" "role" "soup" "advertising" "location" "success" "addition" "apartment" "education" "math" "moment" "painting" "politics" "attention" "decision" "event" "property" "shopping" "student" "wood" "competition" "distribution" "entertainment" "office" "population" "president" "unit" "category" "cigarette" "context" "introduction" "opportunity" "performance" "driver" "flight" "length" "magazine" "newspaper" "relationship" "teaching" "cell" "dealer" "finding" "lake" "member" "message" "phone" "scene" "appearance" "association" "concept" "customer" "death" "discussion" "housing" "inflation" "insurance" "mood" "woman" "advice" "blood" "effort" "expression" "importance" "opinion" "payment" "reality" "responsibility" "situation" "skill" "statement" "wealth" "application" "city" "county" "depth" "estate" "foundation" "grandmother" "heart" "perspective" "photo" "recipe" "studio" "topic" "collection" "depression" "imagination" "passion" "percentage" "resource" "setting" "ad" "agency" "college" "connection" "criticism" "debt" "description" "memory" "patience" "secretary" "solution" "administration" "aspect" "attitude" "director" "personality" "psychology" "recommendation" "response" "selection" "storage" "version" "alcohol" "argument" "complaint" "contract" "emphasis" "highway" "loss" "membership" "possession" "preparation" "steak" "union" "agreement" "cancer" "currency" "employment" "engineering" "entry" "interaction" "mixture" "preference" "region" "republic" "tradition" "virus" "actor" "classroom" "delivery" "device" "difficulty" "drama" "election" "engine" "football" "guidance" "hotel" "owner" "priority" "protection" "suggestion" "tension" "variation" "anxiety" "atmosphere" "awareness" "bath" "bread" "candidate" "climate" "comparison" "confusion" "construction" "elevator" "emotion" "employee" "employer" "guest" "height" "leadership" "mall" "manager" "operation" "recording" "sample" "transportation" "charity" "cousin" "disaster" "editor" "efficiency" "excitement" "extent" "feedback" "guitar" "homework" "leader" "mom" "outcome" "permission" "presentation" "promotion" "reflection" "refrigerator" "resolution" "revenue" "session" "singer" "tennis" "basket" "bonus" "cabinet" "childhood" "church" "clothes" "coffee" "dinner" "drawing" "hair" "hearing" "initiative" "judgment" "lab" "measurement" "mode" "mud" "orange" "poetry" "police" "possibility" "procedure" "queen" "ratio" "relation" "restaurant" "satisfaction" "sector" "signature" "significance" "song" "tooth" "town" "vehicle" "volume" "wife" "accident" "airport" "appointment" "arrival" "assumption" "baseball" "chapter" "committee" "conversation" "database" "enthusiasm" "error" "explanation" "farmer" "gate" "girl" "hall" "historian" "hospital" "injury" "instruction" "maintenance" "manufacturer" "meal" "perception" "pie" "poem" "presence" "proposal" "reception" "replacement" "revolution" "river" "son" "speech" "tea" "village" "warning" "winner" "worker" "writer" "assistance" "breath" "buyer" "chest" "chocolate" "conclusion" "contribution" "cookie" "courage" "dad" "desk" "drawer" "establishment" "examination" "garbage" "grocery" "honey" "impression" "improvement" "independence" "insect" "inspection" "inspector" "king" "ladder" "menu" "penalty" "piano" "potato" "profession" "professor" "quantity" "reaction" "requirement" "salad" "sister" "supermarket" "tongue" "weakness" "wedding" "affair" "ambition" "analyst" "apple" "assignment" "assistant" "bathroom" "bedroom" "beer" "birthday" "celebration" "championship" "cheek" "client" "consequence" "departure" "diamond" "dirt" "ear" "fortune" "friendship" "funeral" "gene" "girlfriend" "hat" "indication" "intention" "lady" "midnight" "negotiation" "obligation" "passenger" "pizza" "platform" "poet" "pollution" "recognition" "reputation" "shirt" "sir" "speaker" "stranger" "surgery" "sympathy" "tale" "throat" "trainer" "uncle" "youth" "time" "work" "film" "water" "money" "example" "while" "business" "study" "game" "life" "form" "air" "day" "place" "number" "part" "field" "fish" "back" "process" "heat" "hand" "experience" "job" "book" "end" "point" "type" "home" "economy" "value" "body" "market" "guide" "interest" "state" "radio" "course" "company" "price" "size" "card" "list" "mind" "trade" "line" "care" "group" "risk" "word" "fat" "force" "key" "light" "training" "name" "school" "top" "amount" "level" "order" "practice" "research" "sense" "service" "piece" "web" "boss" "sport" "fun" "house" "page" "term" "test" "answer" "sound" "focus" "matter" "kind" "soil" "board" "oil" "picture" "access" "garden" "range" "rate" "reason" "future" "site" "demand" "exercise" "image" "case" "cause" "coast" "action" "age" "bad" "boat" "record" "result" "section" "building" "mouse" "cash") "List of nouns used in password-generator-words function."
  :group 'password-generator
  :type '(repeat string))

(defcustom password-generator-vocabulary-verbs '("accept" "accuse" "achieve" "acknowledge" "acquire" "adapt" "add" "adjust" "admire" "admit" "adopt" "adore" "advise" "afford" "agree" "aim" "allow" "announce" "anticipate" "apologize" "appear" "apply" "appreciate" "approach" "approve" "argue" "arise" "arrange" "arrive" "ask" "assume" "assure" "astonish" "attach" "attempt" "attend" "attract" "avoid" "awake" "bake" "bathe" "be" "bear" "beat" "become" "beg" "begin" "behave" "believe" "belong" "bend" "bet" "bind" "bite" "blow" "boil" "borrow" "bounce" "bow" "break" "breed" "bring" "broadcast" "build" "burn" "burst" "buy" "calculate" "can/could" "care" "carry" "catch" "celebrate" "change" "choose" "chop" "claim" "climb" "cling" "come" "commit" "communicate" "compare" "compete" "complain" "complete" "concern" "confirm" "consent" "consider" "consist" "consult" "contain" "continue" "convince" "cook" "cost" "count" "crawl" "create" "creep" "criticize" "cry" "cut" "dance" "dare" "deal" "decide" "defer" "delay" "deliver" "demand" "deny" "depend" "describe" "deserve" "desire" "destroy" "determine" "develop" "differ" "disagree" "discover" "discuss" "dislike" "distribute" "dive" "do" "doubt" "drag" "dream" "drill" "drink" "drive" "drop" "dry" "earn" "eat" "emphasize" "enable" "encourage" "engage" "enhance" "enjoy" "ensure" "entail" "enter" "establish" "examine" "exist" "expand" "expect" "experiment" "explain" "explore" "extend" "fail" "fall" "feed" "feel" "fight" "find" "finish" "fit" "fly" "fold" "follow" "forbid" "forget" "forgive" "freeze" "fry" "generate" "get" "give" "go" "grind" "grow" "hang" "happen" "hate" "have" "hear" "hesitate" "hide" "hit" "hold" "hop" "hope" "hug" "hurry" "hurt" "identify" "ignore" "illustrate" "imagine" "imply" "impress" "improve" "include" "incorporate" "indicate" "inform" "insist" "install" "intend" "introduce" "invest" "investigate" "involve" "iron" "jog" "jump" "justify" "keep" "kick" "kiss" "kneel" "knit" "know" "lack" "laugh" "lay" "lead" "lean" "leap" "learn" "leave" "lend" "lie" "lift" "light" "like" "listen" "look" "lose" "love" "maintain" "make" "manage" "matter" "may" "mean" "measure" "meet" "melt" "mention" "might" "mind" "miss" "mix" "mow" "must" "need" "neglect" "negotiate" "observe" "obtain" "occur" "offer" "open" "operate" "order" "organize" "ought to" "overcome" "overtake" "owe" "own" "paint" "participate" "pay" "peel" "perform" "persuade" "pinch" "plan" "play" "point" "possess" "postpone" "pour" "practice" "prefer" "prepare" "pretend" "prevent" "proceed" "promise" "propose" "protect" "prove" "pull" "punch" "pursue" "push" "put" "qualify" "quit" "react" "read" "realize" "recall" "receive" "recollect" "recommend" "reduce" "refer" "reflect" "refuse" "regret" "relate" "relax" "relieve" "rely" "remain" "remember" "remind" "repair" "replace" "represent" "require" "resent" "resist" "retain" "retire" "rid" "ride" "ring" "rise" "risk" "roast" "run" "sanction" "satisfy" "say" "scrub" "see" "seem" "sell" "send" "serve" "set" "settle" "sew" "shake" "shall" "shed" "shine" "shoot" "should" "show" "shrink" "shut" "sing" "sink" "sit" "ski" "sleep" "slice" "slide" "slip" "smell" "snore" "solve" "sow" "speak" "specify" "spell" "spend" "spill" "spit" "spread" "squat" "stack" "stand" "start" "steal" "stick" "sting" "stink" "stir" "stop" "stretch" "strike" "struggle" "study" "submit" "succeed" "suffer" "suggest" "supply" "suppose" "surprise" "survive" "swear" "sweep" "swell" "swim" "swing" "take" "talk" "taste" "teach" "tear" "tell" "tend" "think" "threaten" "throw" "tiptoe" "tolerate" "translate" "try" "understand" "vacuum" "value" "vary" "volunteer" "wait" "wake" "walk" "want" "warn" "wash" "watch" "wave" "wear" "weep" "weigh" "whip" "will" "win" "wish" "would" "write") "List of verbs used in password-generator-words function."
  :group 'password-generator
  :type '(repeat string))

(defcustom password-generator-vocabulary-adjectives '("different" "used" "important" "every" "large" "available" "popular" "able" "basic" "known" "various" "difficult" "several" "united" "historical" "hot" "useful" "mental" "scared" "additional" "emotional" "old" "political" "similar" "healthy" "financial" "medical" "traditional" "federal" "entire" "strong" "actual" "significant" "successful" "electrical" "expensive" "pregnant" "intelligent" "interesting" "poor" "happy" "responsible" "cute" "helpful" "recent" "willing" "nice" "wonderful" "impossible" "serious" "huge" "rare" "technical" "typical" "competitive" "critical" "electronic" "immediate" "aware" "educational" "environmental" "global" "legal" "relevant" "accurate" "capable" "dangerous" "dramatic" "efficient" "powerful" "foreign" "hungry" "practical" "psychological" "severe" "suitable" "numerous" "sufficient" "unusual" "consistent" "cultural" "existing" "famous" "pure" "afraid" "obvious" "careful" "latter" "unhappy" "acceptable" "aggressive" "boring" "distinct" "eastern" "logical" "reasonable" "strict" "administrative" "automatic" "civil" "former" "massive" "southern" "unfair" "visible" "alive" "angry" "desperate" "exciting" "friendly" "lucky" "realistic" "sorry" "ugly" "unlikely" "anxious" "comprehensive" "curious" "impressive" "informal" "inner" "pleasant" "sexual" "sudden" "terrible" "unable" "weak" "wooden" "asleep" "confident" "conscious" "decent" "embarrassed" "guilty" "lonely" "mad" "nervous" "odd" "remarkable" "substantial" "suspicious" "tall" "tiny" "more" "some" "one" "all" "many" "most" "other" "such" "even" "new" "just" "good" "any" "each" "much" "own" "great" "another" "same" "few" "free" "right" "still" "best" "public" "human" "both" "local" "sure" "better" "general" "specific" "enough" "long" "small" "less" "high" "certain" "little" "common" "next" "simple" "hard" "past" "big" "possible" "particular" "real" "major" "personal" "current" "left" "national" "least" "natural" "physical" "short" "last" "single" "individual" "main" "potential" "professional" "international" "lower" "open" "according" "alternative" "special" "working" "true" "whole" "clear" "dry" "easy" "cold" "commercial" "full" "low" "primary" "worth" "necessary" "positive" "present" "close" "creative" "green" "late" "fit" "glad" "proper" "complex" "content" "due" "effective" "middle" "regular" "fast" "independent" "original" "wide" "beautiful" "complete" "active" "negative" "safe" "visual" "wrong" "ago" "quick" "ready" "straight" "white" "direct" "excellent" "extra" "junior" "pretty" "unique" "classic" "final" "overall" "private" "separate" "western" "alone" "familiar" "official" "perfect" "bright" "broad" "comfortable" "flat" "rich" "warm" "young" "heavy" "valuable" "correct" "leading" "slow" "clean" "fresh" "normal" "secret" "tough" "brown" "cheap" "deep" "objective" "secure" "thin" "chemical" "cool" "extreme" "exact" "fair" "fine" "formal" "opposite" "remote" "total" "vast" "lost" "smooth" "dark" "double" "equal" "firm" "frequent" "internal" "sensitive" "constant" "minor" "previous" "raw" "soft" "solid" "weird" "amazing" "annual" "busy" "dead" "false" "round" "sharp" "thick" "wise" "equivalent" "initial" "narrow" "nearby" "proud" "spiritual" "wild" "adult" "apart" "brief" "crazy" "prior" "rough" "sad" "sick" "strange" "external" "illegal" "loud" "mobile" "nasty" "ordinary" "royal" "senior" "super" "tight" "upper" "yellow" "dependent" "funny" "gross" "ill" "spare" "sweet" "upstairs" "usual" "brave" "calm" "dirty" "downtown" "grand" "honest" "loose" "male" "quiet" "brilliant" "dear" "drunk" "empty" "female" "inevitable" "neat" "ok" "representative" "silly" "slight" "smart" "stupid" "temporary" "weekly" "that" "this" "what" "which" "time" "these" "work" "no" "only" "then" "first" "money" "over" "business" "his" "game" "think" "after" "life" "day" "home" "economy" "away" "either" "fat" "key" "training" "top" "level" "far" "fun" "house" "kind" "future" "action" "live" "period" "subject" "mean" "stock" "chance" "beginning" "upset" "chicken" "head" "material" "salt" "car" "appropriate" "inside" "outside" "standard" "medium" "choice" "north" "square" "born" "capital" "shot" "front" "living" "plastic" "express" "feeling" "otherwise" "plus" "savings" "animal" "budget" "minute" "character" "maximum" "novel" "plenty" "select" "background" "forward" "glass" "joint" "master" "red" "vegetable" "ideal" "kitchen" "mother" "party" "relative" "signal" "street" "connect" "minimum" "sea" "south" "status" "daughter" "hour" "trick" "afternoon" "gold" "mission" "agent" "corner" "east" "neither" "parking" "routine" "swimming" "winter" "airline" "designer" "dress" "emergency" "evening" "extension" "holiday" "horror") "List of adjectives used in password-generator-words function."
  :group 'password-generator
  :type '(repeat string))

(defcustom password-generator-words-gap "." "Gap used between words in password-generator-words function." :group 'password-generator :type 'string)

(defcustom password-generator-simple-length 8 "Password length for password-generator-simple." :group 'password-generator :type 'integer)
(defcustom password-generator-numeric-length 4 "Password length for password-generator-numeric." :group 'password-generator :type 'integer)
(defcustom password-generator-phonetic-length 8 "Password length for password-generator-phonetic." :group 'password-generator :type 'integer)
(defcustom password-generator-strong-length 12 "Password length for password-generator-strong." :group 'password-generator :type 'integer)
(defcustom password-generator-paranoid-length 20 "Password length for password-generator-paranoid." :group 'password-generator :type 'integer)
(defcustom password-generator-words-length 4 "Words count in password generated by password-generator-words function." :group 'password-generator :type 'integer)
(defcustom password-generator-custom-length 8 "Words count in password generated by password-generator-custom function." :group 'password-generator :type 'integer)

(defcustom password-generator-custom-alphabet "абвгдеёжзийклмно" "Alphabet used by password-generator-custom function." :group 'password-generator :type 'string)



;;;###autoload
(defun password-generator-random (max)
  "Random number limited by MAX.  Feel free to rewrite this random.  Just don't make it too slow."
  (let*
      ((random-value (random max)))

    random-value))

;;;###autoload
(defun password-generator-random-list-element (list)
  "Return random element from LIST."
  (nth (- (password-generator-random (length list)) 1) list))


;;;###autoload
(defun password-generator-get-random-string-char (string)
  "You pass here STRING.  You get random character from it."
  (let ((n (password-generator-random (length string))))
    (char-to-string (elt string n))))


;;;###autoload
(defun password-generator-generate-internal (symbols-for-pass pass-length)
  "Generate the password with given vocabulary and length.  SYMBOLS-FOR-PASS is a string contining lphabet used for password generation.  PASS-LENGTH limits the password length."
  (let*
      ((iter 0)
       (password ""))
    (while (< iter pass-length)
      (progn
        (setq
         password
         (concat password (password-generator-get-random-string-char symbols-for-pass)))
         (setq iter (+ 1 iter))))
    password))


;;;###autoload
(defun password-generator-simple (&optional pre-len return)
  "Minimal viable password for most of web systems.  It is not secure but allow to register.  PRE-LEN is prefix arg that defines password lenght.  RETURN specifies if password should be returned or inserted."
  (interactive)
  (let* (
         (password "")
         (pass-length (or pre-len current-prefix-arg password-generator-simple-length))
         (symbols-for-pass "abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
    (setq password (password-generator-generate-internal symbols-for-pass pass-length))
    (cond ((equal nil return) (insert password)) (t password))))


;;;###autoload
(defun password-generator-strong (&optional pre-len return)
  "The best password you can get.  Some symbols does not included to make you free from problems which occurs when your shell try interpolate $, \\ and others.  PRE-LEN is prefix arg that defines password lenght.  RETURN specifies if password should be returned or inserted."
  (interactive)
  (let* (
         (password "")
         (pass-length (or pre-len current-prefix-arg password-generator-strong-length))
         (symbols-for-pass "abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ_@!.^%,&-"))
    (setq password (password-generator-generate-internal symbols-for-pass pass-length))
    (cond ((equal nil return) (insert password)) (t password))))


;;;###autoload
(defun password-generator-paranoid (&optional pre-len return)
  "Good thing to use if you really care about bruteforce.  Not all applications handle special characters presented in such password properly.  Be ready to escape special characters if you will pass such password via ssh command or so.  PRE-LEN is prefix arg that defines password lenght.  RETURN specifies if password should be returned or inserted."
  (interactive)
  (let* (
         (password "")
         (pass-length (or pre-len current-prefix-arg password-generator-paranoid-length))
         (symbols-for-pass "abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_-+=/?,.><[]{}~"))
    (setq password (password-generator-generate-internal symbols-for-pass pass-length))
    (cond ((equal nil return) (insert password)) (t password))))


;;;###autoload
(defun password-generator-numeric (&optional pre-len return)
  "Yeah, there are sill reasons to use numeric passwords like credit card PIN-code.  PRE-LEN is prefix arg that defines password lenght.  RETURN specifies if password should be returned or inserted."
  (interactive)
  (let* (
         (password "")
         (pass-length (or pre-len current-prefix-arg password-generator-numeric-length))
         (symbols-for-pass "0123456789"))
    (setq password (password-generator-generate-internal symbols-for-pass pass-length))
    (cond ((equal nil return) (insert password)) (t password))))


;;;###autoload
(defun password-generator-phonetic (&optional pre-len return)
  "It will be easy to remeber, because of fonetic, but not so secure...  PRE-LEN is prefix arg that defines password lenght.  RETURN specifies if password should be returned or inserted."
  (interactive)
  (let*
      ((password "")
       (letters-A "eyuioa")
       (letters-B "wrtpsdfghjkzxcvbnm")
       (letters-N "123456789")
       (pass-length (or pre-len current-prefix-arg password-generator-simple-length))
       (iter 0)
       (max-iter (+ 1 (/ pass-length 3))))
    (while (< iter max-iter)
      (progn
        (setq password (concat password
                               (password-generator-get-random-string-char letters-B)
                               (password-generator-get-random-string-char letters-A)
                               (password-generator-get-random-string-char letters-N)))
        (setq iter (+ 1 iter))))
    (setq password (substring password 0 pass-length))
    (cond ((equal nil return) (insert password)) (t password))))

;;;###autoload
(defun password-generator-custom (&optional pre-len return)
  "Password generated with your own alphabet.  PRE-LEN is prefix arg that defines password lenght.  RETURN specifies if password should be returned or inserted."
  (interactive)
  (let* (
         (password "")
         (pass-length (or pre-len current-prefix-arg password-generator-custom-length))
         (symbols-for-pass password-generator-custom-alphabet))
    (setq password (password-generator-generate-internal symbols-for-pass pass-length))
    (cond ((equal nil return) (insert password)) (t password))))



(defun password-generator-words (&optional pre-len return)
  "Correct Horse Battery Staple."
  (interactive)
  (let* (
         (password "")
         (vocabulary (list
                      password-generator-vocabulary-nouns
                      password-generator-vocabulary-adjectives
                      password-generator-vocabulary-verbs))
         (iter 0)
         (max-iter (or pre-len current-prefix-arg 3)))
    (while (< iter max-iter)
      (progn
        (setq iter (+ 1 iter))
        (setq password (concat password
                               (password-generator-random-list-element (password-generator-random-list-element vocabulary)) password-generator-words-gap))))
    (setq password (substring password 0 (- (length password) 1)))
    (cond ((equal nil return) (insert password)) (t password))))


(provide 'password-generator)

;;; password-generator.el  ends here

;;; password-generator.el ends here
