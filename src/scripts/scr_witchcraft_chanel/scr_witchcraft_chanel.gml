//! A micro-library for handling the publish-subscribe pattern.
//!
//! No it isn't a typo, that's her name.

//# feather use syntax-errors

/// @ignore
///
/// @return {Id.DsMap}
function __wchanel_info() {
    static info = ds_map_create();
    return info;
}

/// @ignore
///
/// @param {Any} chanName
/// @return {Any}
function __wchanel_sanitise_channel_name(chanName) {
    gml_pragma("forceinline");
    if (is_nan(chanName)) {
        return "NaN";
    }
    return chanName;
}

/// Subscribe to a channel to get notified when updates happen. Returns the
/// unique ID of this subscription to be used with `wchanel_unsubscribe`.
///
/// @param {Any} chanName
///   The channel name or id to subscribe to.
///
/// @param {Function} onUpdate
///   The function to call when this channel receives an update.
///
/// @return {Real}
function wchanel_subscribe(chanName, onUpdate) {
    var info = __wchanel_info();
    chanName = __wchanel_sanitise_channel_name(chanName);
    if (!ds_map_exists(info, chanName)) {
        info[? chanName] = {
            lastUpdate : undefined,
            hasUpdate : false,
            subscribers : [],
        };
    }
    var chan = info[? chanName];
    var subId = array_length(chan.subscribers);
    array_push(chan.subscribers, onUpdate);
    if (chan.hasUpdate) {
        onUpdate(chan.lastUpdate);
    }
    return subId;
}

/// Unsubscribe from a channel.
///
/// @param {Any} chanName
///   The channel name or id to unsubscribe from.
///
/// @param {Real} subId
///   The ID of the subscription to cancel.
function wchanel_unsubscribe(chanName, subId) {
    var info = __wchanel_info();
    chanName = __wchanel_sanitise_channel_name(chanName);
    if (!ds_map_exists(info, chanName)) {
        return;
    }
    var chan = info[? chanName];
    array_delete(chan.subscribers, subId, 1);
}

/// Publish an update to a channel.
///
/// @param {Any} chanName
///   The channel name or id to publish to.
///
/// @param {Any} value
///   The value to publish.
function wchanel_publish(chanName, value) {
    var info = __wchanel_info();
    chanName = __wchanel_sanitise_channel_name(chanName);
    if (!ds_map_exists(info, chanName)) {
        return;
    }
    var chan = info[? chanName];
    chan.hasUpdate = true;
    chan.lastUpdate = value;
    var subs = chan.subscribers;
    for (var i = array_length(subs) - 1; i >= 0; i -= 1) {
        var onUpdate = subs[i];
        onUpdate(value);
    }
}