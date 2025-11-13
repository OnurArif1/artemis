using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface ICommentService
{
    ValueTask<CommentListViewModel> GetList(CommentFilterViewModel filterViewModel);
    ValueTask<CommentGetViewModel?> GetById(int id);
    ValueTask Create(CreateOrUpdateCommentViewModel viewModel);
    ValueTask Update(CreateOrUpdateCommentViewModel viewModel);
    ValueTask Delete(int id);
}