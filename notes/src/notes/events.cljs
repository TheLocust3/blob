(ns notes.events
  (:require
   [re-frame.core :as re-frame]
   [notes.db :as db]
   [notes.api :as api]
   [central :as central]))

(re-frame/reg-event-db
 ::initialize-db
 (fn [_ _]
   db/default-db))

(re-frame/reg-event-db
 ::get-user-complete
 (fn [db [_ user after]]
   (do
     (re-frame/dispatch [after])
     (assoc db :user user))))

(re-frame/reg-event-db
 ::get-user
 (fn [db [_ after]]
   (do
     (.then (api/get-user)
       #(re-frame/dispatch [::get-user-complete % after]))
     db)))

(re-frame/reg-event-db
 ::list-notes-complete
 (fn [db [_ notes]]
   (assoc db :notes notes)))

(re-frame/reg-event-db
 ::list-notes
 (fn [db _]
   (do
     (if (nil? (:user db))
       (re-frame/dispatch [::get-user ::list-notes-complete])
       (.then (api/list-notes (:email db))
         #(re-frame/dispatch [::list-notes-complete %])))
     db)))
