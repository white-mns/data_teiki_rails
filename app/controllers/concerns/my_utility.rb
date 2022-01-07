module MyUtility
  # クエリパラメータをRunsuck検索用関数とフォーム表示用変数に渡す
  def params_to_form(params, form_params, column_name: nil, params_name: nil, type: nil)
    if %w(number text concat).include? type
      method(:"reference_#{type}_assign").call(params, column_name, params_name)
    end

    form_params[params_name] = params[params_name]
  end

  # 選択式チェックボックスから取得したクエリパラメータをRunsuck検索用クエリに渡す
  def checkbox_params_set_query_any(params, form_params, query_name: nil, checkboxes: nil)
    params[:q][query_name] = []
    unless params["is_form"]
      checkboxes.each do |hash|
        if hash[:first_checked]
          if params[ hash[:params_name] ] == "off"
            params.delete( hash[:params_name] )
          else
            params[ hash[:params_name] ] = "on"
          end
        end
      end
    end

    checkboxes.each do |hash|
      params[:q][query_name].push(hash[:value]) if params[ hash[:params_name] ] == "on"
      form_params[ hash[:params_name] ] = params[ hash[:params_name] ]
    end
  end

  # 単一条件チェックボックスから取得したクエリパラメータをRunsuck検索用クエリに渡す
  def checkbox_params_set_query_single(params, form_params, query_name: nil, checkbox: nil)
    if !params["is_form"] && checkbox[:first_checked]
      params[ checkbox[:params_name] ] = "on"
    end

    params[:q][query_name] = checkbox[:value] if params[ checkbox[:params_name] ] == "on"
    form_params[ checkbox[:params_name] ] = params[ checkbox[:params_name] ]
  end

  # 開閉情報のクエリパラメータ受け渡し
  def toggle_params_to_variable(params, form_params, params_name: nil, first_opened: false)
    form_params[ params_name ] = (!params["is_form"] && first_opened) ? "1" : params[ params_name ]
  end

  # 検索文字列を分割し、Ransackが参照する配列に割り当てる
  def reference_word_assign(params, data_name, param_key, match_suffix)
    return unless params[param_key]

    texts = params[param_key].include?(' ') ? params[param_key].gsub(/[“”]/, "\"").split(" ") : [params[param_key].dup.gsub(/[“”]/, "\"")]

    if texts.is_a?(Array)
      for text in texts do
        if text && text.match("/")
          texts_or = text.split("/")
          for text_or in texts_or do
            reference_word_set(params, data_name, text_or, match_suffix, "any")
          end
        else
          reference_word_set(params, data_name, text, match_suffix, "all")
        end
      end
    end
  end

  def reference_text_assign(params, data_name, param_key)
    reference_word_assign(params, data_name, param_key, "cont")
  end

  # 文字列の除外と完全一致を判定し、Ransackが参照する配列に割り当てる
  def reference_word_set(params, data_name, text, match_suffix, operator_suffix)
    not_suffix = ""
    if text[0] == "-"
      # 除外検索用に添字を変更 「_not_cont_all」か「not_eq_all」になる
      text.slice!(0,1)
      not_suffix = "not_"
      operator_suffix = "all"
      data_name = data_name.gsub(/_or_/, "_and_")
    end

    if text[0] == "\"" && text[-1] == "\""
      # 完全一致に添字を変更
      text.slice!(0,1)
      text.slice!(-1,1)
      match_suffix = "eq"
    end

    param_push(params, data_name + "_" + not_suffix + match_suffix + "_" + operator_suffix, text)
  end

  # 検索文字列を分割し、Ransackが参照する配列に割り当てる
  def reference_concat_assign(params, data_name, param_key)
    return unless params[param_key]

    match_suffix = "cont"

    texts = (params[param_key].include?(' ')) ? params[param_key].gsub(/[“”]/, "\"").split(" ") : [params[param_key].dup.gsub(/[“”]/, "\"")]

    if texts.is_a?(Array)
      for text in texts do
        if text && text.match("/")
          texts_or = text.split("/")
          for text_or in texts_or do
            reference_concat_set(params, data_name, text_or, match_suffix, "any")
          end
        else
          reference_concat_set(params, data_name, text, match_suffix, "all")
        end
      end
    end
  end

  # 文字列の除外と完全一致を判定し、Ransackが参照する配列に割り当てる
  def reference_concat_set(params, data_name, text, match_suffix, operator_suffix)
    # 完全一致の記号を文字列連結データのカンマに置き換え
    text = text.gsub(/"/, ",")

    not_suffix = ""
    if text[0] == "-"
      # 除外検索用に添字を変更 「_not_cont_all」か「not_eq_all」になる
      text.slice!(0,1)
      not_suffix = "not_"
      operator_suffix = "all"
      data_name = data_name.gsub(/_or_/, "_and_")
    end

    param_push(params, data_name + "_" + not_suffix + match_suffix + "_" + operator_suffix, text)
  end

  # 数値の文字列を分割し、Ransackが参照する配列に割り当てる
  def reference_number_assign(params, data_name, param_key)
    return unless params[param_key]

    texts = (params[param_key].include?('/')) ? params[param_key].split("/") : [params[param_key].dup]

    if texts.is_a?(Array)
      for text in texts do
        if text && text.match(/([\-\.\d]+)~([\-\.\d]+)/)
          text_match = text.match(/([\-\.\d]+)~([\-\.\d]+)/)
          reference_number_set(params, data_name, text_match[0] + "~")
          reference_number_set(params, data_name, "~" + text_match[2])
        else
          reference_number_set(params, data_name, text)
        end
      end
    end
  end

  # 数値の文字列から以上・以下を判定し、Ransackが参照する配列に割り当てる
  def reference_number_set(params, data_name, text)
    match_suffix = "eq"
    if text[0] == "~"
      text.slice!(0,1)
      match_suffix = "lteq"
    end

    if text[-1] == "~"
      text.slice!(-1,1)
      match_suffix = "gteq"
    end

    param_push(params, data_name + "_" + match_suffix + "_any", text)
  end

  # Ransackの検索用パラメータに追加。配列がない場合は作成する
  def param_push(params, ransack_param, text)
    unless params[:q][ransack_param].is_a?(Array)
      params[:q][ransack_param] = Array.new
    end

    params[:q][ransack_param].push(text)
  end

  def params_clean(params)
    sort = params[:q][:s] if params[:q] && params[:q][:s]
    params[:q] = {}
    params[:q][:s] = sort if sort
  end

  # キャラ周囲絞り込み用
  def girth_matching(params, form_params)
    unless params["is_form"]
      params["place_result_no_form"] ||= sprintf("%d",@latest_result)
    end

    params_tmp = { q: {} }
    params_tmp["place_result_no_form"] = params["place_result_no_form"]
    params_tmp["place_e_no_form"] = params["place_e_no_form"]
    params_tmp["place_pc_name_form"] = params["place_pc_name_form"]

    params_to_form(params_tmp, form_params, column_name: "result_no", params_name: "place_result_no_form", type: "number")
    params_to_form(params_tmp, form_params, column_name: "e_no", params_name: "place_e_no_form", type: "number")
    params_to_form(params_tmp, form_params, column_name: "pc_name_name", params_name: "place_pc_name_form", type: "text")

    if params["place_e_no_form"] || params["place_pc_name_form"]
      place_array = Place.pc_to_place_array(params_tmp)
      params[:q]["place_area_eq_any"] = place_array
      params[:q]["place_field_id_eq_any"] = Place.pc_to_field_id(params_tmp)
    end

    form_params["place_result_no_form"] = params["place_result_no_form"]
    form_params["place_e_no_form"] = params["place_e_no_form"]
    form_params["place_pc_name_form"] = params["place_pc_name_form"]

    toggle_params_to_variable(params, form_params, params_name: "show_girth")
  end

  # PTM絞り込み用
  def pm_matching(params, form_params)
    unless params["is_form"]
      params["pm_result_no_form"] ||= sprintf("%d",@latest_result)
    end

    params_tmp = { q: {} }
    params_tmp["is_form"] = "1"
    params_tmp["pm_result_no_form"] = params["pm_result_no_form"]
    params_tmp["pm_e_no_form"] = params["pm_e_no_form"]
    params_tmp["pm_pc_name_form"] = params["pm_pc_name_form"]
    params_tmp["pm_party_type_form"] = params["pm_party_type_form"]
    params_tmp["pm_battle"] = params["pm_battle"]
    params_tmp["pm_next"]   = params["pm_next"]

    params_to_form(params_tmp, @form_params, column_name: "result_no", params_name: "pm_result_no_form", type: "number")
    params_to_form(params_tmp, @form_params, column_name: "e_no", params_name: "pm_e_no_form", type: "number")
    params_to_form(params_tmp, @form_params, column_name: "pc_name_name", params_name: "pm_pc_name_form", type: "text")
    checkbox_params_set_query_any(params_tmp, @form_params, query_name: "party_type_eq_any",
                              checkboxes: [{params_name: "pm_battle", value: 0, first_checked: false},
                                          {params_name: "pm_next" ,  value: 1, first_checked: true}])

    if params["pm_e_no_form"] || params["pm_pc_name_form"]
      party_member_array = Party.pc_to_party_member_array(params_tmp)
      if params[:q]["e_no_eq_any"]
        params[:q]["e_no_eq_any"] = params[:q]["e_no_eq_any"].push(party_member_array).flatten
      else
        params[:q]["e_no_eq_any"] = party_member_array
      end
    end

    # フォームに値を受け渡す用の空実行
    checkbox_params_set_query_any(params, @form_params, query_name: "xxx",
                              checkboxes: [{params_name: "pm_battle", value: 0, first_checked: false},
                                          {params_name: "pm_next" ,  value: 1, first_checked: true}])

    form_params["pm_result_no_form"] = params["pm_result_no_form"]
    form_params["pm_e_no_form"] = params["pm_e_no_form"]
    form_params["pm_pc_name_form"] = params["pm_pc_name_form"]
    form_params["pm_battle"] = params["pm_battle"]
    form_params["pm_next"] = params["pm_next"]

    toggle_params_to_variable(params, form_params, params_name: "show_pm")
  end

  private
end
