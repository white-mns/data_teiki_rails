// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .
//= require jquery
//= require popper
//= require bootstrap-sprockets
//= require "jquery.cleanQuery"
//= require chartkick

// 検索遷移時の検索フォームの閉じる処理
function search_close() {
    tbody_0 = $(".search_toggle").children().eq(0);
    tbody_0.find(".act_desc").toggle();
    tbody_0.nextAll().hide();
};

// 検索遷移時の詳細トグルを開く処理
function detail_toggle_open() {
    $(".tbody_toggle").find('input:hidden').not("#base_first").each( function(index, element) {
        if ($(this).val() == "1") {
            $(this).nextAll().toggle();
        }
    });
};

function desc_close() {
    $(".desc .card-header").each( function() {
        $(this).next().toggle();
        $(this).find(".act_desc").toggle();
    });
};

function set_triggers() {
    $(".desc .card-header").on("click", function() {
        $(this).next().slideToggle(200);
        $(this).find(".act_desc").toggle();
    });

    $(".example_toggle").on("click", function() {
        $(this).parent().next().slideToggle(200);
        $(this).find(".act_desc").toggle();
    });

    $(".search_toggle").children().eq(0).on("click", function() {
        $(this).nextAll().toggle();
        $(this).find(".act_desc").toggle();
        $(this).nextAll(".tbody_toggle").find('input:hidden').not("#base_first").each( function() {
            if ($(this).val() != "1") { // 詳細項目を表示していない場合は再度隠す
                $(this).parents("tbody").next().hide();
            }
        } );
    });

    $(".tbody_toggle").on("click", function() {
        $(this).next().toggle();
        $(this).find('input:hidden').each( function(index, element) {
            $(element).val( (Number($(element).val()) + 1) % 2 );
        } );
        $(this).find(".act_desc").toggle();
    });

    $(".td_toggle").on("click", function() {
        $(this).next().slideToggle();
        $(this).find(".act_desc").toggle();
    });
};

// ページ表示時の詳細トグル初期開閉処理
function base_first_toggle() {
    $(".tbody_toggle").find('#base_first').each( function(index, element) {
        if ($(this).val() == "1") {
            $(this).nextAll().toggle();
        }
    });
}

// ツールチップの表示処理
function set_tooltip() {
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        placement = "right";

        if (tooltipTriggerEl.getAttribute("data-bs-placement")) placement = tooltipTriggerEl.getAttribute("data-bs-placement");

        return new bootstrap.Tooltip(tooltipTriggerEl, {placement: placement, html: true});
    })
}

// 検索実行後の遷移で説明・検索フォームを閉じる処理
function exec_searched() {
	var url     = location.href;
    var params  = url.split("?");

	if((params[1] && !(params[1] == "no_result=on" || params[1] == "no_count=on")) || window.innerWidth < 767){
        search_close();
        detail_toggle_open();
        desc_close();
        base_first_toggle(); // 初期遷移時にクエリが入るページではトグル開閉状態が逆になるため、もう一度トグル実行
	}
}

// ページ表示時に必ず実行する処理
function exec_load() {
    set_triggers();
    set_tooltip();
    base_first_toggle();
}

// ページ移動時の発火処理
var turboReady = function(){

    $('FORM').cleanQuery();
    exec_searched();
    exec_load();
};

$(document).on('turbolinks:load', turboReady);

