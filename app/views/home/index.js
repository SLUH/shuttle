$(window).ready(function() {
  $('.translate-link').click(function() {
    var sha = $(this).data('sha');
    var project = $(this).data('project');
    var localeField =  $('#translate-link-locale-' + sha);
    var locale = localeField.val();

    var url = '/locales/' + encodeURIComponent(locale) + '/projects/' + encodeURIComponent(project) + '?commit=' + sha;
    window.location = url;

    return false;
  });

  new SmartForm($('#new_commit'), function() { window.location.reload(); });
  $('#new_commit_project_id').change(function() {
    var project = $(this).val();
    $('#new_commit').attr('action', '/projects/' + project + '/commits.json');
  });

  $('.show-request-translation-form-link').click(function(e){
    $(this).hide();
    $('.request-translation-form').slideDown();
    e.preventDefault();
  });

  $('.edit_commit select').change(function() {
    var select = $(this);
    var form = select.closest('form');
    var authParam = $('meta[name=csrf-param]').attr('content');
    var authToken = $('meta[name=csrf-token]').attr('content');
    var data = form.serializeObject();
    data[authParam] = authToken;

    $.ajax(form.attr('action'), {
      data: data,
      type: 'PUT',
      success: function() {
        var checkmark = $('<i/>').addClass('icon-ok priority-change-success').insertAfter(select);
        checkmark.oneTime(3000, function() { checkmark.fadeOut(); });
      },
      error: function() {
        alert("Couldn't change commit priority.");
      }
    });
  });
});
