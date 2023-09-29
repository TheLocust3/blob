(ns notes.components.menu
  (:require
    [re-frame.core :as re-frame]
    [spade.core :refer [defclass]]
    [central :as central]
    [notes.routes :as routes]
    [notes.events :as events]
    [notes.subs :as subs]))

(defclass pane-style []
  {:display "flex"
   :align-items "center"
   :background-color "white"
   :height "50px"
   :padding-left "10px"
   :padding-right "10px"
   :border-bottom (str "1px solid" central/Constants.colors.black)
   :box-shadow (str "0px 0px 1px" central/Constants.colors.lightBlack)
   :justify-content "space-between"})
(defn pane [children] (into [:div {:class (pane-style)}] children))

(defclass title-style [] {:font-size "20px" :color central/Constants.colors.black})
(defn title [children] (into [:div {:class (title-style)}] children))

(defclass more-style []
  {:padding-top "5px"
   :padding-right "30px"
   :margin-left "auto"
   :margin-right "0"}
  (at-media {:max-width "750px"}
    {:padding-right "5px"}))
(defn more [child] [:div {:class (more-style)} child])

(defclass delete-style []
  {:cursor "pointer"
   :color central/Constants.colors.black}
  [:&:hover {:color central/Constants.colors.red}])
(defn delete [attrs child] [:div (merge-with + attrs {:class (delete-style)}) child])

(defclass open-style []
  {:padding-top "4px"
   :padding-right "8px"
   :cursor "pointer"}
   [:&:hover {:color "black"}]
   [:&:active {:color "black"}])
(defn open [attrs children] (into [:div (merge-with + attrs {:class (open-style)})] children))

(defn build []
  (let [selected @(re-frame/subscribe [::subs/selected])
        sidebar-open? @(re-frame/subscribe [::subs/sidebar-open?])]
    
    (pane [(if (not sidebar-open?) (open {:on-click (fn [] (re-frame/dispatch [::events/sidebar-open]))} [[:> central/Icon {:icon "menu" :size "1.25em"}]]))
           (title [(:title selected)])
           (if (nil? selected) [:div] (more (delete {:on-click (fn [] (re-frame/dispatch [::events/delete-note (:title selected) [::events/navigate ::routes/index]]))} [:> central/Icon {:icon "delete" :size "1.25em"}])))])))
